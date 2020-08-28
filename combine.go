package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

// This holds the standard structure of our logs.
type line struct {
	Level      string    `json:"level"`
	Timestamp  time.Time `json:"ts"`
	Controller string    `json:"knative.dev/controller"`
	Caller     string    `json:"caller"`
	Key        string    `json:"knative.dev/key"`
	Message    string    `json:"msg"`
	Error      string    `json:"error"`
	// For easier printing, stash the full line here too. Dump. but ok for now.
	FullLine string
	File     string
}

type lineSlice []line

// Forward request for length
func (ls lineSlice) Len() int {
	return len(ls)
}

// Define compare
func (ls lineSlice) Less(i, j int) bool {
	return ls[i].Timestamp.Before(ls[j].Timestamp)
}

// Define swap over an array
func (ls lineSlice) Swap(i, j int) {
	ls[i], ls[j] = ls[j], ls[i]
}

func main() {
	dir := flag.String("dir", "", "Directory")
	key := flag.String("key", "", "Key to look for")
	namespace := flag.String("namespace", "", "Namespace to look for events for")
	flag.Parse()

	if *dir == "" {
		log.Fatal("Need to specify dir with -dir")
	}
	if *namespace == "" && *key == "" {
		log.Fatal("Need to specify namespace or key with -namespace and/or -key")
	}

	fmt.Printf("reading dir %q\n", *dir)

	var files []string
	err := filepath.Walk(*dir, func(path string, info os.FileInfo, err error) error {
		if !info.IsDir() {
			files = append(files, path)
		}
		return nil
	})
	if err != nil {
		panic(err)
	}
	matcher := ""
	if *namespace != "" {
		matcher = *namespace + "/"
	} else {
		matcher = "/"
	}
	if *key != "" {
		matcher = matcher + *key
	}

	matchLines := make(lineSlice, 0)

	log.Printf("looking for key: %q", matcher)
	for _, fileName := range files {
		log.Printf("Processing file: %q", fileName)
		file, err := os.Open(fileName)
		if err != nil {
			log.Fatalf("Failed to open %q : %s", file, err)
		}
		defer file.Close()
		scanner := bufio.NewScanner(file)
		for scanner.Scan() {
			l := scanner.Text()
			var inLine line
			if err := json.Unmarshal([]byte(l), &inLine); err != nil {
				// Ignore malformed lines.
				continue
			}
			if strings.Contains(inLine.Key, matcher) {
				inLine.FullLine = l
				inLine.File = fileName
				matchLines = append(matchLines, inLine)
				//				fmt.Printf("%s : %s\n", fileName, l)
			}
		}
		if err := scanner.Err(); err != nil {
			log.Fatal(err)
		}
	}

	// Sort...
	sort.Sort(matchLines)
	for _, l := range matchLines {
		fmt.Printf("%s %s\n", l.File, l.FullLine)
	}
}
