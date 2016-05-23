#!/usr/bin/perl
package sql;
use strict;
use warnings;
use URI;
use Encode;
use DBI;

my $txt;
$txt= encode("utf-8",decode("gbk",$txt));

my $dbname = "spider";         #固定
my $location = "127.0.0.1";
my $port = "3306"; #这是mysql的缺省
my $database = "DBI:mysql:$dbname:$location:$port";

my $db_user = "root";
my $db_pass = "";

our $tablename ||= "douban_book_jg";   #our,必须修改tablename
my $sql;
my $sth;
my @data; #数据集
                                        #info
# 数据库字段	id	url	bookname	author	press	time	price	rata_number	rate_person
#&select();
#&delete(20);     #id
#&select();
#&insert(21,'ddd','e','press','9.2','4532');
#&select();
#&truncate_table();
#&select();
#&create_table();
#&drop_table();
#&show_tables();

sub select{
my $dbh = DBI->connect($database,$db_user,$db_pass);  #建立连接
$dbh->do("SET NAMES 'UTF8'");
$sql = "SELECT *  FROM $tablename";
$sth = $dbh->prepare($sql);#准备
$sth->execute() or die "无法执行SQL语句:$dbh->errstr"; #执行
while (@data = $sth->fetchrow_array()) { #fetchrow_array返回row
print "id:$data[0]\t url:$data[1]\t bookname:$data[2]\t info:$data[3]\t rata_number:$data[4]\t rata_person:$data[5]\n";
}
$sth->finish();
$dbh->disconnect;#断开数据库连接
}

#id	url	bookname	author	press	time	price	rata_number	rate_person
sub insert{
my $dbh = DBI->connect($database,$db_user,$db_pass);  #建立连接
$dbh->do("SET NAMES 'UTF8'");
$sql = "replace into $tablename values (?,?,?,?,?,?)";
#$sql = "insert ignore into $tablename values (?,?,?,?,?)";
$sth = $dbh->prepare($sql);#准备
$sth->execute($_[0],$_[1],$_[2],$_[3],$_[4],$_[5]) or die "无法执行SQL语句:$dbh->errstr"; #执行
$sth->finish();
$dbh->disconnect;#断开数据库连接
}

sub delete{
my $dbh = DBI->connect($database,$db_user,$db_pass);  #建立连接
$sql = "delete from $tablename where id=?";
$sth = $dbh->prepare($sql);#准备
$sth->execute($_[0]) or die "无法执行SQL语句:$dbh->errstr"; #执行
$sth->finish();
$dbh->disconnect;#断开数据库连接
}

sub truncate_table{
my $dbh = DBI->connect($database,$db_user,$db_pass);  #建立连接
$sql = "truncate table $tablename";
$sth = $dbh->prepare($sql);#准备
$sth->execute() or die "无法执行SQL语句:$dbh->errstr"; #执行
$sth->finish();
$dbh->disconnect;#断开数据库连接
}

sub drop_table{
my $dbh = DBI->connect($database,$db_user,$db_pass);  #建立连接
$sql = "drop table $tablename";
$sth = $dbh->prepare($sql);#准备
$sth->execute() or die "无法执行SQL语句:$dbh->errstr"; #执行
$sth->finish();
$dbh->disconnect;#断开数据库连接
}

sub show_tables{
my $dbh = DBI->connect($database,$db_user,$db_pass);  #建立连接
$sql = "show tables";
$sth = $dbh->prepare($sql);#准备
$sth->execute() or die "无法执行SQL语句:$dbh->errstr"; #执行
while (@data = $sth->fetchrow_array()) { #fetchrow_array返回row
print "@data\n";
}
$sth->finish();
$dbh->disconnect;#断开数据库连接
}

sub create_table{
my $dbh = DBI->connect($database,$db_user,$db_pass);  #建立连接
$sql = "DROP TABLE IF EXISTS $tablename";
$sth = $dbh->prepare($sql);#准备
$sth->execute() or die "无法执行SQL语句:$dbh->errstr"; #执行
$sth->finish();
                   ####分开执行sql语句  汗
$sql = <<"SQL";
CREATE TABLE $tablename (
`id`  int(11) NOT NULL DEFAULT 0 ,
`url`  char(60) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
`bookname`  varchar(40) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
`info`  varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
`rate_number`  float UNSIGNED NULL DEFAULT 0 ,
`rate_person`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
;
SQL
$sth = $dbh->prepare($sql);#准备
$sth->execute() or die "无法执行SQL语句:$dbh->errstr"; #执行
$sth->finish();

$dbh->disconnect;#断开数据库连接
}
1;
