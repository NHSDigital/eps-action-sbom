package main

import (
    "fmt"
    "github.com/pkg/errors"
)

func main() {
    fmt.Println("Modules example")
    _ = errors.New("sample error")
}
