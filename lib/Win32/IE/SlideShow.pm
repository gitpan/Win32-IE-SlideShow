package Win32::IE::SlideShow;

use strict;
use warnings;
use Win32::OLE;

our $VERSION = '0.01';

sub new {
  my ($class, %options) = @_;

  my $invoked;
  my $appkey = 'InternetExplorer.Application';
  my $ie = Win32::OLE->GetActiveObject( $appkey );
  unless ( defined $ie ) {
    $ie = Win32::OLE->new( $appkey ) or die Win32::OLE->LastError;
    $invoked = 1;
  }

  $ie->{Visible} = 0;
  my @keys = qw( FullScreen TheaterMode Top Left Height Width );
  foreach my $key ( @keys ) {
    $ie->{$key} = $options{$key} if exists $options{$key};
  }
  $ie->Navigate('about:blank');
  $ie->{Visible} = 1;

  my $self = bless { ie => $ie, invoked => $invoked }, $class;

  $self;
}

sub set {
  my ($self, @slides) = @_;
  $self->{slides} = \@slides;
  $self->{total}  = scalar @slides;
  $self->{index}  = 0;
}

sub set_callback {
  my ($self, $callback) = @_;

  $self->{converter} = $callback;
}

sub total { shift->{total} }

sub start { shift->goto(1) }

sub goto {
  my ($self, $page) = @_;

  # "page" (which viewers may see) should start from 1,
  # but "index" (used internally) should start from 0.
  $self->{index} = $page - 1;
  $self->next;
}

sub next {
  my $self = shift;

  my $slide = $self->{slides}->[$self->{index}++];

  if ( $self->{converter} ) {
    $slide = $self->{converter}->( $slide );
  }

  my $document = $self->{ie}->{Document};
     $document->open( "text/html", "replace" );
     $document->write( $slide );

  # actually this "index" points to the next slide,
  # however, "index" + 1 happens to be the same as the "page".
  return $self->{index};
}

sub has_next {
  my $self = shift;

  return $self->{index} < $self->{total} ? 1 : 0;
}

sub quit {
  my $self = shift;
  if ( $self->{ie} && $self->{invoked} ) {
    $self->{ie}->Quit;
    delete $self->{ie};
  }
}

sub DESTROY { shift->quit }

1;

__END__

=head1 NAME

Win32::IE::SlideShow - show and manipulate your slides on IE

=head1 SYNOPSIS

    use Win32::IE::SlideShow;

    my $show = Win32::IE::SlideShow->new;
    $show->set( @slides );
    while ( $show->has_next ) {
      $show->next;
      sleep 1;
    }

=head1 DESCRIPTION

How do you present your slides? PowerPoint isn't so bad, but creating PowerPoint slides is a bit tedious. A bunch of HTML pages (which, of course, can be created by various perl scripts) with a JavaScript controller may be nice if you don't care writing JavaScript, but, as we're perl mongers, why not use perl to control slides, too? Generally speaking, Mech-ing is the best and portable but today I'm going to use Win32::OLE and Internet Explorer to get a bit more complete control.

=head1 METHODS

=head2 new

creates an object and invokes IE if necessary.
You can pass several options to fine tune the appearance of IE:

=over 4

=item FullScreen, TheaterMode

Both can be used to hide other windows but TheaterMode shows some controller.

=item Top, Left, Height, Width

adjust size/position of IE window.

=back

=head2 set

takes an array of complete HTML pages to show, or an array of some formatted texts if you provide some on-the-fly converter with set_callback (see below).

=head2 set_callback

If you prefer, you can provide a code reference to convert a formatted text into an HTML page on the fly.

=head2 total

returns the number of slides, which may be used to iterate the slides, or to provide some progress indicator.

=head2 start

moves an internal pointer to the first slide, and show it, though you usually don't need to use this.

=head2 next

shows the slide which the pointer currently points, and moves the pointer to the next slide and returns a current "page" number, which you may want to pass to the progress indicator, or use as a base to move to another page with goto method.

=head2 has_next

returns true while the show has slide(s) to show yet.

=head2 goto

moves the internal pointer to an appropriate slide and shows it.

=head2 quit

closes the IE window (if necessary).

=head1 SEE ALSO

L<HTML::Display::Win32::IE>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut
