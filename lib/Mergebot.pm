use v5.28;

package Mergebot;
use Moose;
use warnings;

use Crypt::JWT qw(encode_jwt);
use IO::Async::Loop;
use Plack::Request;
use Plack::Response;
use TOML::Parser;

use Mergebot::GitHubListener;

use experimental 'signatures';

has [qw(
  app_id
  pem_file
  signing_secret
)]=> (
  is => 'ro',
  required => 1,
);

sub from_config ($class, $file) {
  my $cfg = TOML::Parser->new->parse_file($file);
  return $class->new($cfg);
}

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

sub generate_access_token ($self) {
  my $now = time;
  my $data = {
    iat => $now - 60,
    exp => $now + (9 * 60),
    iss => 0 + $self->app_id,
  };

  my $private_pem = `cat mergeomatic.2021-08-13.private-key.pem`;

  my $token = encode_jwt(
    payload => $data,
    alg => 'RS256',
    key => \$private_pem,
  );

  return $token;
}

__PACKAGE__->meta->make_immutable;
