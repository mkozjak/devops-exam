package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"

	"gopkg.in/yaml.v3"
)

type Config struct {
	AppVersion string `yaml:"appVersion"`
}

func bumpSemVerAuto(version string) string {
	// Split the version string by periods
	parts := strings.Split(version, ".")
	if len(parts) != 3 {
		// If the version string doesn't have three parts (major.minor.fix), return an error
		return "Invalid version format"
	}

	// Parse the fix part of the version string
	fix, err := strconv.Atoi(parts[2])
	if err != nil {
		// If the fix part cannot be parsed as an integer, return an error
		return "Invalid fix version"
	}

	// Increment the fix version by 1
	fix++

	// Join the parts back together with periods
	newVersion := fmt.Sprintf("%s.%s.%d", parts[0], parts[1], fix)
	return newVersion
}

func main() {
	// Parse command-line arguments
	chartPtr := flag.String("c", "config.yaml", "path to the YAML file")
	versionPtr := flag.String("n", "", "version to bump to")
	flag.Parse()

	data, err := os.ReadFile(*chartPtr)
	if err != nil {
		log.Fatalf("Error reading YAML file: %v", err)
	}

	// Unmarshal YAML data into map[string]interface{}
	var configMap map[string]interface{}
	err = yaml.Unmarshal(data, &configMap)
	if err != nil {
		log.Fatalf("Error unmarshalling YAML: %v", err)
	}

	// Check if "appVersion" key exists in the YAML
	if appVersion, ok := configMap["appVersion"]; ok {
		log.Println("Current chart app version is", appVersion)

		// Determine the new version
		var newVersion string
		if *versionPtr == "" {
			log.Println("Version not provided. Bumping via semver.")
			newVersion = bumpSemVerAuto(appVersion.(string))
		} else {
			newVersion = *versionPtr
		}

		// Update the appVersion in the map
		configMap["appVersion"] = newVersion
		log.Println("Setting version to", newVersion)
	} else {
		log.Fatalf("appVersion key not found in the YAML file")
	}

	// Marshal updated map to YAML
	updatedData, err := yaml.Marshal(&configMap)
	if err != nil {
		log.Fatalf("Error marshalling YAML: %v", err)
	}

	// Write the updated YAML data back to file
	err = os.WriteFile(*chartPtr, updatedData, 0644)
	if err != nil {
		log.Fatalf("Error writing YAML file: %v", err)
	}

	log.Println("Bumping done.")
}
