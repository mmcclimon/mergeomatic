use v5.28;

package Mergebot::GitHubEvent::IssueComment;
use Moose;
use experimental 'signatures';

has event => (
  is => 'ro',
  required => 1,
);

has action => (
  is => 'ro',
  lazy => 1,
  default => sub { $_[0]->event->payload->{action} },
);

has body => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my $body = $_[0]->event->payload->{comment}{body};
    $body =~ s/^\s*|\s*$//g;
    return $body;
  },
);

has is_on_pull_request => (
  is => 'ro',
  lazy => 1,
  default => sub {
    return !! $_[0]->event->payload->{issue}{pull_request};
  },

);

sub from_event ($class, $event) {
  return $class->new({ event => $event });
}


__PACKAGE__->meta->make_immutable;
