// Copyright © 2018 Maxim Kovrov
package main

import (
	log "github.com/sirupsen/logrus"
)

func initLog() {
	log.SetFormatter(&log.JSONFormatter{})
}

// must logs and panics if err is not equals to nil
func must(err error) {
	if err != nil {
		log.WithError(err).Panic(err)
	}
}

func main() {
	initLog()
	execute()
}
