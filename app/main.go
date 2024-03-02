package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"

	_ "github.com/go-sql-driver/mysql"
)

type User struct {
	Name  string
	Email string
}

func main() {
	// Initiate database connection
	db, err := sql.Open("mysql", "username:password@tcp(mysql:3306)/devops")
	if err != nil {
		log.Fatal(err)
	}

	defer db.Close()

	// Fetch users
	rows, err := db.Query("SELECT name, email FROM users")
	if err != nil {
		log.Fatal(err)
	}

	defer rows.Close()

	var users []User

	for rows.Next() {
		var user User
		if err := rows.Scan(&user.Name, &user.Email); err != nil {
			log.Fatal(err)
		}

		users = append(users, user)
	}

	if err := rows.Err(); err != nil {
		log.Fatal(err)
	}

	// HTTP handler to display all users
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "<h1>Users</h1>")
		fmt.Fprintf(w, "<ul>")

		for _, user := range users {
			fmt.Fprintf(w, "<li>Name: %s, Email: %s</li>", user.Name, user.Email)
		}

		fmt.Fprintf(w, "</ul>")
	})

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"status": "ok"}`)
	})

	// Start HTTP server
	log.Fatal(http.ListenAndServe(":8080", nil))
}
