{ pkgs ? import <nixpkgs> {} }:

let
  greeting = "Hello, world";
in
pkgs.writeText "greeting" greeting
