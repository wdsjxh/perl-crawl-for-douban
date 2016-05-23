#!/usr/bin/perl
use strict;
use warnings;
use URI;
use Web::Scraper;
use Encode;
use threads;
use threads::shared;
use sql;

our $tag;     #标签 文学  流行 文化 生活 经管 科技 
our $start=0;       #页面值   0 20/页    一页20 ，一共999 页面1-50刚好   （经管）
our $type='T';      #搜索类型        type=T 综合排序   R 出版日期排序      S 评价排序
our $flag=1;		   #标记是否应该继续爬虫
our $total=0;       #总页数
our $rest_page;     #剩余页面;
our $thread=5;      #进程数

my %tags=(         #定义所有标签        科技和流行特例
#	"经管" =>"douban_book_jg",
#	"文学" =>"douban_book_wx",
#	"流行" =>"douban_book_lx",
#	"文化" =>"douban_book_wh",
	"生活" =>"douban_book_sh",
	"科技" =>"douban_book_kj",
);
#my @tags=qw(经管  文学 流行 文化 生活 科技);

=pod
whole_scrap
需要
$start=0;
$flag=1;
由计算的$total赋值$rest_page
$page不用管
$tag变量默认经管
执行完之后flag也为0，得初始为1
执行完之后start变了，得初始为0
还有数据库那一块，默认为经管
执行前得先创建table
=cut
#样例
=pod
=cut
for my $key(keys %tags){
##	print "$key =>$tags{$key}\n";
	$sql::tablename=$tags{$key};
#	sql::drop_table();
	sql::create_table();            #先建表
	$tag=$key;                      #页面必需
	&whole_scrape();
}
#$sql::tablename=$tags{'流行'};
#sql::truncate_table();      #删除表,不删表定义
#sql::select();
#sql::select();
#print "$sql::tablename\n";
#$sql::tablename=$tags{"文学"};
#print "$sql::tablename\n";
#sql::create_table();
#sql::show_tables();
#sql::drop_table();         #删除表定义
#sql::show_tables();

sub whole_scrape{
	$start=0;                       #初始，防止下轮无法执行
    $flag=1;
    if($tag eq '科技' or $tag eq '流行'){    #分类处理
    	&page_number2();
    }
    else{
		while($flag){       #循环爬虫，直到抓取不到书籍url为止
			&page_number1();
			$start+=20;     #一页20
		}
	$total=($start-20)/20;   #1000无页面   0.。980 /20,  此时1000/20=50
	$rest_page=$total;
    }
	print "$rest_page\n";    #剩余页面50

	my $time1=time();
	$flag=1;                 #初始flag为1
	my $i=0;
	my @threads;
	while($rest_page>0){           #剩余页面
		if($rest_page<$thread){        #总页面数<进程或者最后期待处理页面<进程数
			$thread=$rest_page;
		}
		for(my $j=0;$j<$thread;$j++){
			 $threads[$j]=threads->create(\&scrap,$i,"thread$j");  #$i等价于$start,thread$j便于观察
			 $i+=20;
		}
		for(my $j=0;$j<$thread;$j++){
			 $threads[$j]->join();
			 $rest_page--;
		}
	}      #while
	
	print "ok ,all complete!\n";
	my $time2=time();
	my $time=$time2-$time1;
	print "time takes $time\n";
}


sub scrap{
	my $page=shift;
	my $tip=shift;
	my $books = scraper {
		process '//div[@class="grid-16-8 clearfix"]//div[@class="article"]//div[@id="subject_list"]//p' => 'flag' => 'TEXT';    #标记结束  没有找到符合条件的图书
		process '//li//div[@class="pic"]//a' => 'site[]' => '@href';
		process '//li//div[@class="info"]//h2//a' => 'title[]' => '@title';
		process '//li//div[@class="info"]//div[@class="pub"]' => 'info[]' => 'TEXT';
		process '//li//div[@class="info"]//div[@class="star clearfix"]//span[@class="rating_nums"]' => 'rating_nums[]' => 'TEXT';
		process '//li//div[@class="info"]//div[@class="star clearfix"]//span[@class="pl"]' => 'person[]' => 'TEXT';
	};
	my $res = $books->scrape( URI->new("https://book.douban.com/tag/$tag?start=$page&type=$type") );
	if(Encode::encode("utf8","$res->{flag}") eq '没有找到符合条件的图书'){      #转码，标量环境
	##	print "超过了\n";
		$flag=0;
	}
	if($flag){
	for $_ (0..$#{$res->{site}}){   
		if(! defined $res->{rating_nums}[$_]){   #未捕捉到初始化为0;
			$res->{rating_nums}[$_]=0;
		}
		my $id=$page+$_+1;         #此处加上id字段
		sql::insert($id,$res->{site}[$_],$res->{title}[$_],$res->{info}[$_],$res->{rating_nums}[$_],$res->{person}[$_]);
	}
#	print "ok,this is page$page,work by $tip\n";
	
	my $num=0;
	$num=int(rand(3)+2);               #2..7
	sleep($num);                        #保险起见
	}
}

sub page_number1{
	my $books = scraper {
		process '//div[@class="grid-16-8 clearfix"]//div[@class="article"]//div[@id="subject_list"]//p' => 'flag' => 'TEXT';    #标记结束  没有找到符合条件的图书
	};
	my $res = $books->scrape( URI->new("https://book.douban.com/tag/$tag?start=$start&type=$type") );
	if(Encode::encode("utf8","$res->{flag}") eq '没有找到符合条件的图书'){      #转码，标量环境
	#	print "超过了\n";
		$flag=0;
	}
	my $num=0;
	$num=int(rand(3)+3);     #1..10
	sleep($num);
}

sub page_number2{
	my $books = scraper {
		process '//div[@class="paginator"]//a' => 'array[]' => 'TEXT';    #标记结束  没有找到符合条件的图书
	};
	my $res = $books->scrape( URI->new("https://book.douban.com/tag/$tag?start=0&type=$type") );
	$rest_page=$res->{array}[-1];     #最后一个元素
}
