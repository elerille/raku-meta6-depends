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

use META6::Depends;
use Test;

use JSON::Fast;
use META6;

indir $?FILE.IO.parent, {

    my %ecosystem = "cpan.json" => "https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/cpan.json",
                    "p6c.json" => "https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/p6c.json",
                    ;
    for %ecosystem.sort {
        next if .key.IO.e;
        unless run <wget -nv -O>, .key, .value {
            bail-out "Unable to download " ~ .key ~ " from " ~ .value.raku;
        }
    }

    my @metas;
    for <cpan.json p6c.json> {
        @metas.push: |from-json $?FILE.IO.parent.add($_).slurp;
    }

    @metas .= sort({ .<name>, .<version>.Version });


    my %skip = 'Config:ver<1.3.5>' => 'use "version" instead of "ver"',
               'Config:ver<2.0.0>' => 'use "version" instead of "ver"',
               'Config:ver<2.0.1>' => 'use "version" instead of "ver"',
               'Config:ver<2.1.0>' => 'use "version" instead of "ver"',
               'Config:ver<3.0.0>' => 'use "version" instead of "ver"',
               'Config:ver<3.0.1>' => 'use "version" instead of "ver"',
               'Config:ver<3.0.3>' => 'use "version" instead of "ver"',
               'Config:ver<3.0.4>' => 'use "version" instead of "ver"',
               'Net::netent:ver<0.0.3>' => 'have a malformed deps',
               'Pod::Weave:ver<0.0.2>' => 'have a deps start by "v" in <...>',
               'String::Color:ver<0.0.3>' => 'have a malformed deps',
               'orion:ver<0.2.2>' => 'have a malformed deps ("::auth<..>" instead of ":auth<..>")',
               ;

    plan +@metas;

    for @metas {
        my $meta = quietly META6.new: json => to-json $_;
        my $module = $meta.name ~ ":ver<" ~ $meta.version ~ ">";
        if %skip{$module}:exists {
            skip $module ~ ' ' ~ %skip{$module}
        } else {
            lives-ok { META6::Depends.from-meta($meta) }, $module;
            META6::Depends.from-meta($meta);
        }
    }

    unlink %ecosystem.keys;
}



done-testing;
