use v5.28;

package Mergebot;
use Moose;
use warnings;

use IO::Async::Loop;
use Net::Async::HTTP::Server::PSGI;
use Plack::Request;
use Plack::Response;

use Mergebot::GitHubListener;

use experimental 'signatures';

has _registered_paths => (
  is      => 'ro',
  isa     => 'HashRef',
  traits  => [ 'Hash' ],
  default => sub { {} },
  handles => {
    register_pathname  => 'set',
    path_is_registered => 'exists',
    app_for_path       => 'get',
  },
);

has github_listener => (
  is => 'ro',
  lazy => 1,
  default => sub { Mergebot::GitHubListener->new },
);

sub BUILD ($self, @) {
  $self->register_pathname('/gh', $self->github_listener);
}

sub to_app ($self) {
  return sub ($env) {
    my $req = Plack::Request->new($env);
    my $path_info = $req->path_info // '/';

    unless ($self->path_is_registered($path_info)) {
      warn "couldn't find path for $path_info, ignoring\n";
      return Plack::Response->new(404)->finalize;
    }

    return $self->app_for_path($path_info)->handle_request($req);
  };
}


__PACKAGE__->meta->make_immutable;
