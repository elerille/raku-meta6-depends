# Copyright 2021 Élerille
#
# This file is part of META6::Depends.
# 
# META6::Depends is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# META6::Depends is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with META6::Depends.  If not, see <https://www.gnu.org/licenses/>.

unit class META6::Depends;
use META6;

has $.name;
has Str @.cmp;
has Str() @.ver;
has UInt $.api;
has Str() $.auth;
has Str:D $.from where <raku native bin>.any = 'raku';

submethod TWEAK {
    if @!cmp.not && so @!ver {
        if @!ver == 1 {
            if @!ver[0].ends-with('+') {
                @!ver[0].=substr(0, *- 1);
                @!cmp.push: '>=';
            } elsif @!ver[0].ends-with('.*') {
                while @!ver[0].ends-with('.*') {
                    @!ver[0] .= substr(0, *- 2);
                }
                @!cmp.push: '=';
            } elsif @!ver[0] eq '*' {
                @!ver.pop;
            } else {
                @!cmp.push: '=';
            }
        } elsif @!ver == 2 {
            @!cmp = '>=', '<<';
            if @!ver[1] eq '*' {
                @!ver.pop;
                @!cmp.pop;
            }
            if @!ver[0] eq '*' {
                @!ver.shift;
                @!cmp.shift;
            }
        } else {
            die "Version have { +@!ver } parts, this isn't supported";
        }
    }
}

method fmt(::?CLASS:D: --> Str) {
    my $ret = $!from.fmt("%-6s") ~ " " ~ $!name.raku.fmt("%-45s");
    $ret ~= ' ' ~ @!ver».Version».gist.join(' ').fmt("%-15s") if @!ver;
    $ret ~= (' :api(' ~ $_ ~ ')').fmt("%-10s") with $!api;
    $ret ~= ' :auth(' ~ $_ ~ ')' with $!auth;
    $ret;
}


#| %depends<runtime>
#| %depends<build>
#| %depends<test>
#| %depends<*><requires>
#| %depends<*><recommends>
method from-meta(META6:D $meta --> Hash:D) {
    my %depends;

    %depends<test><requires> = parse-array($meta.test-depends) if $meta.test-depends;
    %depends<build><requires> = parse-array($meta.build-depends) if $meta.build-depends;
    with $meta.depends {
        when Array:D {
            %depends<runtime><requires>.push: |parse-array($_);
        }
        when Hash:D {
            for $_.kv -> $phase, $_ {
                for $_.kv -> $level, $_ {
                    when Array:D {
                        %depends{$phase}{$level}.push: |parse-array($_);
                    }
                    default {
                        say "[C] ", .^name, " ", $_;
                        die;
                    }

                }
            }
        }
        default {
            say "[B] ", .^name, " ", $_;
            die;
        }
    }
    %depends;
}



grammar Module-Name {
    token TOP {
        <name>
        <ext>*
    }
    token name { <name-part> ** 1..* % '::' }
    token name-part { <-[:]>+ }
    token ext {
        ":" [<ver> | <api> | <auth> | <from>]
    }
    token ver {
        "ver<" <number=version-number> ">"
        | "ver(" <number=v-version-number> [\s* '..' \s* <number=v-version-number>]? ")"
    }
    token api {
        "api<" <number> ">"
        | <number> "api"
    }
    token auth {
        "auth<" <( <-[>]>+ )> ">"
    }
    token from {
        "from<" <( ["native" | "bin"] )> ">"
    }
    token v-version-number {
        'v' <version-number>
        | '*'
    }
    token version-number {
        <number> ** 1..* % '.' ['+'? | '.' '*' ** 1..* % '.']
    }
    token number {
        <[0..9]>+
    }

}


class Depends-Action {
    method TOP($/) {
        my %kvargs;
        for $<ext>».made {
            for @$_ { %kvargs{.key} = .value }
        }
        my @ver;
        with %kvargs<ver> {
            @ver = |$_;
            %kvargs<ver>:delete;
        }
        make META6::Depends.new: name => ~$<name>, :@ver, |%kvargs;
    }
    method ext($/) {
        with $<ver> {
            make $(:ver($<ver><number>».made));
        } orwith $<api> {
            make $(:api(+$<api><number>));
        } orwith $<auth> {
            make $(:auth(~$<auth>));
        } orwith $<from> {
            make $(:from(~$<from>));
        } else {
            die "[ERROR] Unable to make : ", $/;
        }
    }
    method version-number($/) {
        make ~$/;
    }
    method v-version-number($/) {
        if ~$/ eq '*' { make '*' }
        else { make $<version-number>.made }
    }
}

sub parse-array(@list, Bool :$alternative = True --> Array) {
    my @ret;
    for @list {
        when Str:D {
            @ret.push: Module-Name.parse($_, :actions(Depends-Action.new)).made // die "[Nil] ", $_.raku;
        }
        when Array:D {
            @ret.push: $_.map({ Module-Name.parse($_, :actions(Depends-Action.new)).made // die "[Nil] ", $_ });
        }
        when Hash:D {
            @ret.push: META6::Depends.new: |$_;
        }
        when Any:U {}
        default {
            say "[A] ", .^name, " ", $_;
            die;
        }
    }
    @ret;
}
