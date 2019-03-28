package main

import (
	"bufio"
	"encoding/json"
	"io"
)

const (
	fieldMsg  = "msg"
	fieldTime = "time"
	fieldLvl  = "level"
	fieldErr  = "error"
	fieldRaw  = "raw"
)

type jsonView struct {
	r  io.Reader
	oo []map[string]interface{}
}

func (w *jsonView) read(height int) error {
	reader := bufio.NewReader(w.r)
	w.oo = make([]map[string]interface{}, 0, height)
	for len(w.oo) < height {
		l, err := reader.ReadBytes('\n')
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}
		o := map[string]interface{}{}
		err = json.Unmarshal(l, &o)
		if err != nil {
			o[fieldErr] = err.Error()
			o[fieldMsg] = "Error while convert line to JSON"
			o[fieldRaw] = string(l)
		}
	}
	return nil
}
