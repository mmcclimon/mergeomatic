use v5.28;

package Mergebot::Job;
use Moose;
use experimental 'signatures';

use IO::Async::Loop;

has loop => (
  is => 'ro',
  lazy => 1,
  default => sub { IO::Async::Loop->new },
);

has inciting_comment => (
  is => 'ro',
  isa => 'Mergebot::GitHubEvent::IssueComment',
  required => 1,
);

sub BUILD ($self, @) {
  die "whoa, you can't make a job for a not-pull-request"
    unless $self->inciting_comment->is_on_pull_request;
}

sub run ($self) {
  $self->loop->run_process(
    code => sub {
      sleep 5;
      warn "hey, we're done!";
    }
  );
}


__PACKAGE__->meta->make_immutable;


