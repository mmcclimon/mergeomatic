#!perl
use v5.28;
use warnings;

use lib 'lib';
use Mergebot;

return Mergebot->from_config('mergebot.toml')->to_app;
