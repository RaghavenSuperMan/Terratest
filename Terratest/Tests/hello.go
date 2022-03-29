package main

import (
  "fmt"
  "os"
  "strconv"
)

func main() {
  fmt.Printf("Hello, World!\n")

  fmt.Printf("The sum of 2 and 3 is 5.\n")

  first, _ := strconv.Atoi(os.Args[1])
  second, _ := strconv.Atoi(os.Args[2])
  sum := first + second

  fmt.Printf("The sum of %s and %s is %s.",
    os.Args[1], os.Args[2], strconv.Itoa(sum))
}