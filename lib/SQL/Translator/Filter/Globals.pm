package SQL::Translator::Filter::Globals;

# -------------------------------------------------------------------
# $Id: Globals.pm,v 1.1 2006-03-06 17:46:57 grommit Exp $
# -------------------------------------------------------------------
# Copyright (C) 2002-4 SQLFairy Authors
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; version 2.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
# 02111-1307  USA
# -------------------------------------------------------------------

=head1 NAME

SQL::Translator::Filter::Globals - Add global fields and indices to all tables.

=head1 SYNOPSIS

  # e.g. Add timestamp field to all tables.
  use SQL::Translator;

  my $sqlt = SQL::Translator->new(
      from => 'MySQL',
      to   => 'MySQL',
      filters => [
        Globals => {
            fields => [
                {
                    name => 'modified'
                    data_type => 'TIMESTAMP'
                }
            ],
            indices => [
                { 
                    fields => 'modifed',
                },
            ]
        },
      ],
  ) || die "SQLFairy error : ".SQL::Translator->error;
  my $sql = $sqlt->translate || die "SQLFairy error : ".$sqlt->error;

=cut

use strict;
use vars qw/$VERSION/;
$VERSION=0.1;

sub filter {
    my $schema = shift;
    my %args = @_;
    my $global_table = $args{global_table} ||= '_GLOBAL_';

    my (@global_fields, @global_indices);
    push @global_fields, @{ $args{fields} }   if $args{fields};
    push @global_indices, @{ $args{indices} } if $args{indices};

    # Pull fields and indices off global table and then remove it.
    if ( my $gtbl = $schema->get_table( $global_table ) ) {

        foreach ( $gtbl->get_fields ) {
            # We don't copy the order attrib so the added fields should get
            # pushed on the end of each table.
            push @global_fields, {
                name                  => $_->name,
                comments              => "".$_->comments,
                data_type             => $_->data_type,
                default_value         => $_->default_value,
                size                  => [$_->size],
                extra                 => scalar($_->extra),
                foreign_key_reference => $_->foreign_key_reference,
                is_auto_increment     => $_->is_auto_increment,
                is_foreign_key        => $_->is_foreign_key,
                is_nullable           => $_->is_nullable,
                is_primary_key        => $_->is_primary_key,
                is_unique             => $_->is_unique,
                is_valid              => $_->is_valid,
            };
        }

        foreach ( $gtbl->get_indices ) {
            push @global_indices, {
                name    => $_->name,
                type    => $_->type,
                fields  => [$_->fields],
                options => [$_->options],
            };
        }

        $schema->drop_table($gtbl);
    }

    # Add globalis to tables
    foreach my $tbl ( $schema->get_tables ) {

        foreach my $new_fld ( @global_fields ) {
            # Don't add if field already there
            next if $tbl->get_field( $new_fld->{name} );
            $tbl->add_field( %$new_fld );
        }

        foreach my $new_index ( @global_indices ) {
            # Don't add if already there
            #next if $tbl->get_index( $new_index->{name} );
            $tbl->add_index( %$new_index );
        }
    }
}

1;

__END__

=head1 DESCRIPTION

Adds global fields and indices to all tables in the schema.
The globals to add can either be defined in the filter args or using a _GLOBAL_
table (see below).

If a table already contains a field with the same name as a global then it is
skipped for that table.

=head2 The _GLOBAL_ Table

An alternative to using the args is to add a table called C<_GLOBAL_> to the
schema and then just use the filter. Any fields and indices defined on this table
will be added to all the tables in the schema and the _GLOBAL_ table removed.

The name of the global can be changed using a C<global_table> arg to the
filter.

=head1 SEE ALSO

L<perl(1)>, L<SQL::Translator>

=head1 BUGS

Will generate duplicate indices if an index already exists on a table the same
as one added globally.

=head1 TODO

Global addition of constraints.

Some extra data values that can be used to control the global addition. e.g.
'skip_global'.

=head1 AUTHOR

Mark Addison <grommit@users.sourceforge.net>

=cut
