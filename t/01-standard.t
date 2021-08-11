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

use Test;
use META6::Depends;
use META6;

my %hash = test-depends => "test",
           build-depends => "build",
           depends => "runtime";

my @a = <zef JSON::Class Cro::HTTP::Client>;
for @a {
    for %hash.sort -> (:$key, :$value) {
        my META6 $meta .= new: |($key => [$_]);
        my %result;
        %result{$value}<requires> = [META6::Depends::Depends.new: name => $_];
        my $got = depends($meta);
        is-deeply $got, %result, "$_ on $key";
    }
}
{
    for %hash.sort -> (:$key, :$value) {
        my META6 $meta .= new: |($key => @a);
        my %result;
        %result{$value}<requires> = @a.map({ META6::Depends::Depends.new: name => $_ }).Array;
        is-deeply depends($meta), %result, $key.tc ~ " with " ~ +@a ~ " Str";
    }
}
{
    my META6 $meta .= new: depends => ["zef", ["JSON::Fast", "JSON::Tiny"]];
    my %result;
    %result<runtime><requires> = [
        META6::Depends::Depends.new(:name<zef>),
        [META6::Depends::Depends.new(:name<JSON::Fast>), META6::Depends::Depends.new(:name<JSON::Tiny>)].Seq
    ];
    is-deeply depends($meta), %result, "Simple with alternative";
}
{
    my META6 $meta .= new: depends => ["Cro::HTTP:ver<0.8.3>"];
    my %result;
    %result<runtime><requires> = [META6::Depends::Depends.new(:name<Cro::HTTP>, :ver<0.8.3>),];
    is-deeply depends($meta), %result, "Cro::HTTP:ver<0.8.3>";
}
{
    my META6 $meta .= new: depends => ["Cro::HTTP:ver<0.8.3+>"];
    my %result;
    %result<runtime><requires> = [META6::Depends::Depends.new(:name<Cro::HTTP>, :ver(v0.8.3, '*')),];
    is-deeply depends($meta), %result, "Cro::HTTP:ver<0.8.3+>";
}
for <Cro::HTTP:ver<0.8.3+>:api<1> Cro::HTTP:api<1>:ver<0.8.3+> Cro::HTTP:ver<0.8.3+>:1api Cro::HTTP:1api:ver<0.8.3+>>
{
    my META6 $meta .= new: depends => [$_];
    my %result;
    %result<runtime><requires> = [META6::Depends::Depends.new(:name<Cro::HTTP>, :ver(v0.8.3, '*'), :1api),];
    is-deeply depends($meta), %result, $_;
}
for <IRC::Log::Colabti:ver<0.0.30>:auth<cpan:ELIZABETH> IRC::Log::Colabti:auth<cpan:ELIZABETH>:ver<0.0.30>>
{
    my META6 $meta .= new: depends => [$_];
    my %result;
    %result<runtime><requires> = [META6::Depends::Depends.new(:name<IRC::Log::Colabti>, :ver<0.0.30>, :auth<cpan:ELIZABETH>),];
    is-deeply depends($meta), %result, $_;
}
for ("CPAN::Uploader::Tiny:ver(v0.0.4 .. *)",)
{
    my META6 $meta .= new: depends => [$_];
    my %result;
    %result<runtime><requires> = [META6::Depends::Depends.new(:name<CPAN::Uploader::Tiny>, :ver(v0.0.4, '*')),];
    is-deeply depends($meta), %result, $_;
}
for ("ogg:from<native>",)
{
    my META6 $meta .= new: depends => [$_];
    my %result;
    %result<runtime><requires> = [META6::Depends::Depends.new(:name<ogg>, :from<native>),];
    is-deeply depends($meta), %result, $_;
}
for ("dot:from<bin>",)
{
    my META6 $meta .= new: depends => [$_];
    my %result;
    %result<runtime><requires> = [META6::Depends::Depends.new(:name<dot>, :from<bin>),];
    is-deeply depends($meta), %result, $_;
}
for <License::Software:ver<0.3.*> License::Software:ver<0.3.*.*>>
{
    my META6 $meta .= new: depends => [$_];
    my %result;
    %result<runtime><requires> = [META6::Depends::Depends.new(:name<License::Software>, :ver(v0.3, v0.4)),];
    is-deeply depends($meta), %result, $_;
}


say depends(META6.new: depends => ["Dist::Helper:ver<0.19.0>:2api"]);

done-testing;
