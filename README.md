# FWC
An Iptables compiler written in PERL6


## How to install Perl6
```sh
wget https://rakudo.perl6.org/downloads/star/rakudo-star-2017.01.tar.gz
tar xfz rakudo-star-2017.01.tar.gz
cd rakudo-star-2017.01
perl Configure.pl --gen-moar --prefix /opt/rakudo-star-2017.01
make install
```
For more information, visit http://rakudo.org/how-to-get-rakudo/

### Dependencies(so far)
Module used for printing table [Text Table Simple](https://github.com/ugexe/Perl6-Text--Table--Simple/blob/master/examples/readme-example.pl6)
```sh
zef install Text::Table::Simple
```
