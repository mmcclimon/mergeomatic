use v5.28;

package Mergebot::Job;
use Moose;
use experimental 'signatures';

use Data::Dumper::Concise;
use Future;
use IO::Async::Loop;
use Net::Async::HTTP;

has comment => (
  is => 'ro',
  isa => 'Mergebot::GitHubEvent::IssueComment',
  init_arg => 'inciting_comment',
  required => 1,
);

has hub => (
  is => 'ro',
  required => 1,
  weak_ref => 1,
  handles => [qw( encode_json decode_json )],
);

has loop => (
  is => 'ro',
  lazy => 1,
  default => sub { IO::Async::Loop->new },
);

has http_client => (
  is => 'ro',
  lazy => 1,
  default => sub ($self) {
    # I'm going to assert that if we have a job that takes longer than 10
    # minutes, something has gone wrong, and so it's ok to cache this access
    # token for the duration of our job.
    my $http = Net::Async::HTTP->new(
      max_connections_per_host => 5,
      max_in_flight => 10,
      headers => {
        Authorization => "Bearer " . $self->hub->generate_access_token,
      }
    );

    $self->loop->add($http);
    return $http;
  },
);

has _installation_token => (
  is => 'rw',
);

sub get_installation_token ($self) {
  return Future->done if $self->_installation_token;

  my $iid = $self->comment->installation_id;
  my $url = "https://api.github.com/app/installations/$iid/access_tokens";

  warn "posting to $url";

  return $self->http_client
    ->POST($url, '{}', content_type => 'application/json')
    ->then(sub ($res) {
      my $data = $self->decode_json($res->decoded_content);
      my $token = $data->{token};
      warn "got token $token\n";
      $self->_installation_token($token);
    })
    ->else(sub {
      warn Dumper \@_;
    });
}

sub BUILD ($self, @) {
  die "whoa, you can't make a job for a not-pull-request"
    unless $self->comment->is_on_pull_request;
}

sub run ($self) {
  # we run this in a subprocess so that the webhook isn't waiting around on us
  # to finish.
  $self->loop->run_process(
    code => sub {
      $self->maybe_merge_pr;
      $self->loop->run,
    },
    on_finish => sub { $self->loop->stop },
  );

  return;
}

sub maybe_merge_pr ($self) {
  my $iid = $self->comment->installation_id;
  my $url = "https://api.github.com/app/installations/$iid/access_tokens";

  $self->get_installation_token
    ->then(sub {
      $self->http_client->GET($self->comment->pr_url,
        headers => {
          Authorization => "token " . $self->_installation_token,
        },
      );
    })
    ->then(sub ($res) {
      my $data = $self->decode_json($res->decoded_content);
      warn Dumper $data;
    })
    ->else(sub {
      warn Dumper \@_;
    })
    ->retain;
}


__PACKAGE__->meta->make_immutable;


