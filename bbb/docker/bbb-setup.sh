#!/bin/bash

sudo yq e -i '.public.app.askForConfirmationOnLeave = false | .public.layout.showSessionDetailsOnJoin = false' /etc/bigbluebutton/bbb-html5.yml
