package main

import (
	"fmt"
	"io"

	"github.com/jroimartin/gocui"
)

const (
	viewHelp = "help"
	viewMain = "main"
)

var showHelp = false

func show(r io.Reader) error {
	g, err := gocui.NewGui(gocui.OutputNormal)
	if err != nil {
		return err
	}
	defer g.Close()
	g.SetManagerFunc(layout)

	must(g.SetKeybinding("", gocui.KeyCtrlC, gocui.ModNone, quit))
	must(g.SetKeybinding("", 'q', gocui.ModNone, quit))
	must(g.SetKeybinding("", 'h', gocui.ModNone, toggleHelp))

	if err := g.MainLoop(); err != nil && err != gocui.ErrQuit {
		must(err)
	}
	return nil
}

func layout(g *gocui.Gui) error {
	maxX, maxY := g.Size()
	if v, err := g.SetView(viewMain, maxX/2-7, maxY/2-2, maxX/2+7, maxY/2+2); err != nil {
		if err != gocui.ErrUnknownView {
			return err
		}
		fmt.Fprintln(v, "Hello world!") // nolint: errcheck
	}

	if showHelp {
		if v, err := g.SetView(viewHelp, 0, 0, 5, 3); err != nil {
			if err != gocui.ErrUnknownView {
				return err
			}
			fmt.Fprintln(v, "Help") // nolint: errcheck
		}
	} else {
		g.DeleteView(viewHelp) // nolint: errcheck,gosec
	}

	return nil
}

func quit(g *gocui.Gui, v *gocui.View) error {
	return gocui.ErrQuit
}

func toggleHelp(g *gocui.Gui, v *gocui.View) error {
	showHelp = !showHelp
	return nil
}
