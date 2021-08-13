use v5.28;

package Mergebot::GitHubListener;
use Moose;
use experimental 'signatures';

use Data::Dumper::Concise;
use IO::Async::Loop;
use IO::Async::Process;

use Mergebot::GitHubEvent;
use Mergebot::Job;

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

  my $event = Mergebot::GitHubEvent->from_plack_request($req);

  unless ($event) {
    return to_psgi(400, 'malformed request');
  }

  $self->maybe_handle_event($event);

  return [ 200, [], [] ];
}

sub maybe_handle_event ($self, $event) {
  my $type   = $event->type;
  my $method = "handle_$type";

  warn "considering event " . $event->id . "\n";

  return unless $self->can($method);

  $self->$method($event);
}

sub handle_issue_comment ($self, $event) {
  my $comment = $event->as_issue_comment;

  return if $comment->action eq 'deleted';  # nothing to do
  return unless $comment->is_on_pull_request;

  # ok, so if our body says /mergeomatic merge me, we'll do a thing
  return unless $comment->body eq '/mergeomatic merge me';

  my $job = Mergebot::Job->new({ inciting_comment => $comment });
  $job->run;
}

__PACKAGE__->meta->make_immutable;
