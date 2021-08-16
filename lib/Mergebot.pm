use v5.28;

package Mergebot;
use Moose;
use warnings;

use IO::Async::Loop;
use Plack::Request;
use Plack::Response;

use Mergebot::GitHubListener;

use experimental 'signatures';

has json_codec => (
  is => 'ro',
  lazy => 1,
  default => sub { JSON::MaybeXS->new },
  handles => {
    encode_json => 'encode',
    decode_json => 'decode',
  },
);

has handlers => (
  is => 'ro',
  lazy => 1,
  isa => 'HashRef',
  traits => ['Hash'],
  default => sub ($self) {
    return {
      '/gh' => Mergebot::GitHubListener->new({ hub => $self }),
    }
  },
  handles => {
    handler_for => 'get',
  },
);

sub to_app ($self) {
  return sub ($env) {
    my $req = Plack::Request->new($env);
    my $path_info = $req->path_info // '/';

    my $handler = $self->handler_for($path_info);

    unless ($handler) {
      warn "couldn't find path for $path_info, ignoring\n";
      return Plack::Response->new(404)->finalize;
    }

    return $handler->handle_request($req);
  };
}

__PACKAGE__->meta->make_immutable;
