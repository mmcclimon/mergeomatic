use v5.28;

package Mergebot::GitHubEvent::IssueComment;
use Moose;
use experimental 'signatures';

# gross
sub _from_raw ($self, @path) {
  my $data = $self->event->payload;
  $data = $data->{$_} for @path;
  return $data;
}

has event => (
  is => 'ro',
  required => 1,
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
    return !! $_[0]->_from_raw(qw(issue pull_request));
  },
);

for my $pair (
  [ action          => [qw( action )] ],
  [ pr_url          => [qw( issue pull_request url )] ],
  [ installation_id => [qw( installation id )] ],
) {
  my ($attr, $path) = @$pair;
  has $attr => (
    is => 'ro',
    lazy => 1,
    default => sub { $_[0]->_from_raw(@$path) },
  );
}

sub from_event ($class, $event) {
  return $class->new({ event => $event });
}


__PACKAGE__->meta->make_immutable;
