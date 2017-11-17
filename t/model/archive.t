#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use MetaCPAN::TestHelpers qw( fakecpan_dir );
use Test::Deep qw( cmp_bag );
use Test::More;
use Digest::SHA1 qw( sha1_hex );
use Test::Fatal qw( exception );

my $CLASS = 'MetaCPAN::Model::Archive';
require_ok $CLASS;

subtest 'missing required arguments' => sub {
    like( exception { $CLASS->new; }, qr{archive} );
};

subtest 'file does not exist' => sub {
    my $file = 'hlaglhalghalghj.blah';

    like(
        exception { $CLASS->new( file => $file ); },
        qr{does not exist},
        'exception thrown'
    );
};

subtest 'archive extraction' => sub {
    my %want = (
        'Some-1.00-TRIAL/lib/Some.pm' =>
            '2f806b4c7413496966f52ef353984dde10b6477b',
        'Some-1.00-TRIAL/Makefile.PL' =>
            'bc7f47a8e0e9930f41c06e150c7d229cfd3feae7',
        'Some-1.00-TRIAL/t/00-nop.t' =>
            '2eba5fd5f9e08a9dcc1c5e2166b7d7d958caf377',
        'Some-1.00-TRIAL/META.json' => qr/"meta-spec"/,
        'Some-1.00-TRIAL/META.yml'  => qr/provides:/,
        'Some-1.00-TRIAL/MANIFEST' =>
            'e93d21831fb3d3cac905dbe852ba1a4a07abd991',
    );

    my $archive = $CLASS->new(
        file => fakecpan_dir->child(
            '/authors/id/L/LO/LOCAL/Some-1.00-TRIAL.tar.gz')
    );

    ok !$archive->is_impolite;
    ok !$archive->is_naughty;

    cmp_bag $archive->files, [ keys %want ];

    my $dir = $archive->extract;
    for my $file ( keys %want ) {
        my $content = $dir->file($file)->slurp;
        if ( ref $want{$file} ) {
            like $content, $want{$file}, "content of $file";
        }
        else {
            my $digest = sha1_hex($content);
            is $digest, $want{$file}, "content of $file";
        }
    }
};

subtest 'temp cleanup' => sub {
    my $tempdir;

    {
        my $archive = $CLASS->new(
            file => fakecpan_dir->child(
                'authors/id/L/LO/LOCAL/Some-1.00-TRIAL.tar.gz')
        );

        $tempdir = $archive->extract;
        ok -d $tempdir;

        # stringify to get rid of the temp object so $tempdir doesn't keep
        # it alive
        $tempdir = "$tempdir";
    }

    ok !-d $tempdir;
};

subtest 'extract once' => sub {
    my $archive = $CLASS->new(
        file => fakecpan_dir->child(
            'authors/id/L/LO/LOCAL/Some-1.00-TRIAL.tar.gz')
    );

    is $archive->extract, $archive->extract;
};

subtest 'set extract dir' => sub {
    my $temp = File::Temp->newdir;

    {
        my $archive = $CLASS->new(
            file => fakecpan_dir->child(
                'authors/id/L/LO/LOCAL/Some-1.00-TRIAL.tar.gz'),
            extract_dir => $temp->dirname
        );

        my $dir = $archive->extract_dir;

        isa_ok $dir, 'Path::Tiny';
        is $dir,     $temp;
        is $archive->extract, $temp;
        ok -s $dir->child('Some-1.00-TRIAL/META.json');
    }

    ok -e $temp, q[Path::Tiny doesn't clean up directories it was handed];
};

done_testing;
