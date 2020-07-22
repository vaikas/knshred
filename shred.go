package main

import (
	"bufio"
	"flag"
	"fmt"
	"log"
	"os"
	"strings"
)

func main() {
	fileName := flag.String("file", "", "File to shred")
	testName := flag.String("test", "", "Test to split out")
	flag.Parse()

	if *fileName == "" {
		log.Fatal("Need to specify inputfile with -file")
	}
	if *testName == "" {
		log.Fatal("Need to specify test with -test")
	}
	outFileName := fmt.Sprintf("%s.%s", *fileName, strings.ReplaceAll(*testName, "/", "-"))
	file, err := os.Open(*fileName)
	if err != nil {
		log.Fatal(err)
	}
	outFile, err := os.Create(outFileName)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()
	defer outFile.Close()

	scanner := bufio.NewScanner(file)
	inTest := false
	// This catches the final --- stuff in the test reports
	testNameWithSpaces := fmt.Sprintf(" %s ", *testName)
	for scanner.Scan() {
		l := scanner.Text()
		if strings.HasPrefix(l, "===") || strings.HasPrefix(l, "---") {
			inTest = false
		}
		if strings.HasSuffix(l, *testName) {
			inTest = true
		}
		if inTest || strings.Contains(l, testNameWithSpaces) {
			_, err := outFile.WriteString(l + "\n")
			if err != nil {
				log.Fatal(err)
			}
		}
	}

	if err := scanner.Err(); err != nil {
		log.Fatal(err)
	}
}
