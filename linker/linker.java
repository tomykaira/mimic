import java.util.regex.*;
import java.io.*;

class linker
{
    public static void main(String args[])
    {
	try
	    {
		int cnt = args.length;
		if (cnt < 2)
		    {
			System.err.println("usage: java linker src1 [src2 src3 ...] dst");
			return;
		    }

		System.err.print("<link> ");

		// open source files
		BufferedReader[] srcs = new BufferedReader[cnt - 1];
		for (int i = 0; i < cnt - 1; i++)
		    {
			FileInputStream srcStream = new FileInputStream(args[i]);
			srcs[i] = new BufferedReader(new InputStreamReader(srcStream, "UTF-8"));
		    }

		// open output file
		FileOutputStream dstStream = new FileOutputStream(args[cnt - 1]);
		OutputStreamWriter dst = new OutputStreamWriter(dstStream, "UTF-8");

		// jump to main
		dst.write("\tj\tmin_caml_start\n");
			
		// write other pieces and close files
		Pattern gotoMainPat = Pattern.compile("j[ \t]+min[_]caml[_]start");
		for (int i = 0; i < cnt - 1; i++)
		    {
			while (true)
			    {
				String line = srcs[i].readLine();
				if (line == null) break;
				// ignore "jmp min_caml_start"
				if (gotoMainPat.matcher(line).find() == false)
				    {
					dst.write(line + "\n");
				    }
			    }
			srcs[i].close();
		    }
		dst.close();
	
		for (int i = 0; i < cnt - 1; i++)
		    {
			System.err.print(args[i] + " ");
		    }
		System.err.println("=> " + args[cnt - 1]);
	    }
	catch (IOException e)
	    {
		// exit when catch excepthion. "make" will stop.
		System.out.println(e);
		System.exit(1);
	    }
    }
}


