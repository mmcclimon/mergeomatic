use v5.28;

package Mergebot::GitHubEvent;
use Moose;
use experimental 'signatures';

use Crypt::Mac::HMAC qw(hmac_hex);

use Mergebot::GitHubEvent::IssueComment;

has [qw(
  type
  id
  payload
)] => (
  is => 'ro',
  required => 1,
);

sub from_plack_request ($class, $req, $signing_secret) {
  state $JSON = JSON::MaybeXS->new;

  # validate signature
  my $gh_sig   = $req->header('X-Hub-Signature-256') // '';
  my $to_check = 'sha256=' . hmac_hex('SHA256', $signing_secret, $req->raw_body);
  return unless $gh_sig eq $to_check;

  my $payload = eval { $JSON->decode($req->content) };
  return unless $payload;

  return $class->new({
    id   => $req->header('X-GitHub-Delivery'),
    type => $req->header('X-GitHub-Event'),
    payload => $payload,
  });
}

sub as_issue_comment ($self) {
  # ...I should just write this in Rust.
  die "lolwut" unless $self->type eq 'issue_comment';
  return Mergebot::GitHubEvent::IssueComment->from_event($self);
}

__PACKAGE__->meta->make_immutable;
