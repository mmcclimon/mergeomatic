#!perl
use v5.28;
use warnings;

use lib 'lib';
use Mergebot;

return Mergebot->new->to_app;
