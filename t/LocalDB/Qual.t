BEGIN {     
    use lib '.';
    use Bio::Root::Test;

    test_begin( -tests => 45,
                -requires_module => 'Bio::DB::Qual');

    use_ok('Bio::Root::IO');
    use_ok('File::Copy');
}

my $DEBUG = test_debug();

{

my $test_dbdir = setup_temp_dir('dbqual');

# now use this temporary dir for the db file
ok my $db = Bio::DB::Qual->new($test_dbdir, -reindex => 1);
isa_ok $db, 'Bio::DB::Qual';
ok my @ids = $db->ids;
is scalar(@ids), 15;
@ids = sort {$a <=> $b} @ids;
is $ids[0] , '17601976';
is $ids[14], '17601991';
my $seqid = '17601979';

# direct indexed qual file database access
is ref($db->qual($seqid)), 'ARRAY';
is $db->length($seqid), 14;
is $db->length($seqid, -1000, 1000), 14;
ok $db->header($seqid);

# the bioperl  way
ok my $obj = $db->get_Qual_by_id($seqid);
ok !defined $db->get_Qual_by_id('foobarbaz');
isa_ok $obj, 'Bio::Seq::PrimaryQual';
is ref($obj->qual($seqid)), 'ARRAY';
is $obj->length, 14;
ok $obj->id;
ok $obj->display_id;
ok $obj->accession_number;
ok $obj->primary_id;
is $obj->validate_qual($obj, (join ' ', @{$obj->qual($seqid)})), 1;
is $obj->translate, 0;
is $obj->qualat(12), 31;
ok !defined($obj->header);
ok !defined($obj->desc);
ok my $truncobj = $obj->trunc(1,3);
isa_ok $truncobj, 'Bio::Seq::PrimaryQual';
is ref($truncobj->qual($seqid)), 'ARRAY';
is $truncobj->length, 3;
ok my $revobj = $obj->revcom;
isa_ok $revobj, 'Bio::Seq::PrimaryQual';
is ref($revobj->qual), 'ARRAY';
is $revobj->length, 14;
undef $obj;
undef $truncobj;
undef $revobj;

# using get_PrimaryQual_stream streaming
ok my $stream = $db->get_PrimaryQual_stream;
ok $stream = $db->get_Seq_stream;
isa_ok $stream, 'Bio::DB::Indexed::Stream';
ok my $streamqual = $stream->next_seq;
isa_ok $streamqual, 'Bio::Seq::PrimaryQual';

# using newFh streaming
ok my $fh = Bio::DB::Qual->newFh($test_dbdir);
my $fhqual = <$fh>;
isa_ok $fhqual, 'Bio::Seq::PrimaryQual';
undef $fh;

# tied-hash access
my (%h,$dna1,$dna2);
ok tie(%h,'Bio::DB::Qual',$test_dbdir);
ok $h{$seqid};
ok $dna1 = $h{"$seqid:1,10"};
ok $dna2 = $h{"$seqid:10,1"};

}



sub setup_temp_dir {
    # this obfuscation is to deal with lockfiles by GDBM_File which can
    # only be created on local filesystems apparently so will cause test
    # to block and then fail when the testdir is on an NFS mounted system

    my $data_dir = shift;

    my $io = Bio::Root::IO->new();
    my $tempdir = test_output_dir();
    my $test_dbdir = $io->catfile($tempdir, $data_dir);
    mkdir($test_dbdir); # make the directory
    my $indir = test_input_file($data_dir);
    opendir(my $INDIR,$indir) || die("cannot open dir $indir");
    # effectively do a cp -r but only copy the files that are in there, no subdirs
    for my $file ( map { $io->catfile($indir,$_) } readdir($INDIR) ) {
        next unless (-f $file );
        copy($file, $test_dbdir);
    }
    closedir($INDIR);
    return $test_dbdir
}