#!/bin/bash

ip route del default
ip route add default via "$1" dev wg0
