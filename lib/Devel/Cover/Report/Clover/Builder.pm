package Devel::Cover::Report::Clover::Builder;
use Template;
use File::Basename qw(dirname);
use Devel::Cover::Report::Clover;
use Devel::Cover::Report::Clover::Project;
use Devel::Cover::Report::Clover::FileRegistry;
use strict;
use warnings;

use base qw(Class::Accessor::Faster);
__PACKAGE__->mk_ro_accessors(qw(db));
__PACKAGE__->mk_accessors(qw(name file_registry project));

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    my %summary_options = map( ( $_ => 1 ), $self->db->collected );
    $summary_options{total} = 1;
    $self->db->calculate_summary(%summary_options);

    $self->project(
        Devel::Cover::Report::Clover::Project->new( { builder => $self, name => $self->name } ) );
    $self->file_registry( Devel::Cover::Report::Clover::FileRegistry->new( { builder => $self } ) );
    return $self;
}

sub generate {
    my ( $self, $outfile ) = @_;

    my $xml = $self->report_xml();

    open( my $fh, '>', $outfile ) or die($!);
    print {$fh} $xml;
    close($fh);

    return $xml;

}

sub report {
    my ($self) = @_;
    my $data = {
        project      => $self->project->report(),
        generated    => time(),
        generated_by => 'Devel::Cover::Report::Clover',
        version      => $Devel::Cover::Report::Clover::VERSION,
    };
    return $data;
}

sub report_xml {
    my ($self) = @_;

    my $tt = Template->new( { INCLUDE_PATH => $self->template_dir, } );

    my $out  = '';
    my $vars = $self->report();

    $tt->process( $self->template_file, $vars, \$out ) || die $tt->error();
    return $out;

}

sub template_file {
    'clover.tt';
}

sub template_dir {
    sprintf( '%s', dirname(__FILE__) );
}

1;
