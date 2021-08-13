use v5.28;

package Mergebot::GitHubListener;
use Moose;
use experimental 'signatures';

use Data::Dumper::Concise;

has json_codec => (
  is => 'ro',
  lazy => 1,
  default => sub { JSON::MaybeXS->new },
  handles => {
    encode_json => 'encode',
    decode_json => 'decode',
  }
);

my sub to_psgi ($self, $code, $content) {
  my $res = Plack::Response->new($code);
  $res->content_type('application/json');
  $res->body($self->encode_json($content));
  return $res->finalize;
}

sub handle_request ($self, $req) {
  return $self->to_psgi(400, { error => 'must POST' })
    unless $req->method eq 'POST';

  # XXX more guff here

  my $data = $self->decode_json($req->content);

  warn Dumper $req->headers;

  warn Dumper $data;



  return [ 200, [], [] ];
}

__PACKAGE__->meta->make_immutable;
