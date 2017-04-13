
可以直接操作的主要有以下几个脚本：

1. ktrace_equiv.pl 
2. make_tau_visible.pl 
3. findloop.pl 
4. produce_lts.pl 

其他的是辅助文件。 


说明：aut文件、class文件都放在input/里， 输出结果在output/里


1. ktrace_equiv.pl 
功能： 
	a. 判定一个商系统(比如lfs23.aut)中的所有的带tau迁移的状态对的等价情况; 
	b. 在指定两个状态情况下，如果两个状态非1-trace等价， 返回一条反例trace，即返回一条在第一个状态的1-trace集合但不在第二个状态1-trace集合里的trace 

用法： 	a.  perl ktrace_equiv.pl input/lfs/lfs23.aut  
	b.  perl ktrace_equiv.pl input/lfs/lfs23.aut  42  43   (表状态号42, 43)
注：
	a. 一般状态对到2-trace就不等价了，有极少数 2-trace 等价但3-trace不等价，所以程序只测到 k <= 4 的 k-trace等价情况。也可以更改脚本里 $k_bound (在第54行)的值来测试更大的k-trace等价情况 。 
	
	b. 输出结果会同时打印到标准输出以及output/里的文件lfs23.aut（假设测试的是lfs23.aut文件），其中(1, 2, 3, 4)_equiv = (10, 2, 0, 0)表示 1-trace等价的有10对，2-trace等价的有2对，不存在3， 4-trace等价对。 



2. make_tau_visible.pl 

功能：给定商系统、class文件、原系统，可以将商系统中的 tau(即 i)还原成真实的迁移。 
用法：perl make_tau_visible.pl  qo.aut  class.txt  big.aut 
注：
	a. 脚本直接将还原后的商系统打印到std上，可以通过重定向输出到指定文件，比如： perl make_tau_visible.pl input/lfs/lfs23.aut  input/lfs/class23.txt  input/lfs/lfs23big.aut > output/visible_lfs23.aut 
	b. 商系统中的一个 tau(即 i)可能对应到原系统上多个不同的action，这种情况下，选择第一个遇到的action。因此，每次输出结果都是一样的。 


3. findloop.pl.  只针对hwqueue的aut文件，测k-trace之前确定不存在环： perl findloop.pl input/hwqueue.aut 



4. produce_lts.pl  
功能： 任给一个迁移图，生成 https://pseuco.com/#/import/lts 可以直接加载的 lts 文件
用法： perl produce_lts.pl  input/msqueue23.aut 
注：   输出结果在output/里，以 "_lts.aut"为后缀。 比如： perl produce_lts.pl input/test.aut 得到 output/test.aut_lts.aut 文件。 




