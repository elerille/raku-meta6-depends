#!/usr/bin/env perl6

use META6::Depends;
use META6;

my $meta = META6.new: file => $?FILE.IO.parent(2).add("META6.json");

for META6::Depends.from-meta($meta).kv -> $scope, %_ {
    for %_.kv -> $level, @_ {
        for @_ {
            say "$scope-$level: ", .name;
        }
    }
}