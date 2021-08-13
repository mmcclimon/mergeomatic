use v5.28;

package Mergebot;
use Moose;
use warnings;

use IO::Async::Loop;
use Plack::Request;
use Plack::Response;

use Mergebot::GitHubListener;

use experimental 'signatures';

sub to_app ($self) {
  my $gh = Mergebot::GitHubListener->new({ hub => $self });

  my %handler_for = (
    '/gh' => $gh,
  );

  return sub ($env) {
    my $req = Plack::Request->new($env);
    my $path_info = $req->path_info // '/';

    my $handler = $handler_for{ $path_info };

    unless ($handler) {
      warn "couldn't find path for $path_info, ignoring\n";
      return Plack::Response->new(404)->finalize;
    }

    return $handler->handle_request($req);
  };
}

__PACKAGE__->meta->make_immutable;
