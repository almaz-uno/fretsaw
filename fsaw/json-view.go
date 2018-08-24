package main

import (
	"encoding/json"
	"bufio"
	"io"
)

const (
	fieldMsg  = "msg"
	fieldTime = "time"
	fieldLvl  = "level"
)

type jsonView struct {
	r  io.Reader
	oo []map[string]interface{}
}

func (w *jsonView) read(height int) error {
	reader := bufio.NewReader(w.r)
	w.oo = make([]map[string]interface{}, 0, lines)
	for len(w.oo) < height {
		l, err := reader.ReadBytes('\n')
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}
		o:=map[string]interface{}{}
		err:=json.Unmarshal(l, &o)
		if err!=nil{
			o["error"]
		}
	}
	return nil
}
