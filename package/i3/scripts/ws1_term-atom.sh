#!/bin/bash

i3-msg "workspace 1; append_layout ~/.config/i3/layouts/ws1_term-atom.json"

(terminator &)
(atom &)
