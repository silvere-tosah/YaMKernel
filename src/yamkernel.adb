with Ada.Text_IO; use Ada.Text_IO;


procedure SparkOs is
   count : Integer := 0;
begin
   put("SparkOs is starting");
   loop
      if count = 15
      then exit;
      else
         Put ('#');
         null;
      end if;
      count := count + 1;
   end loop;
end SparkOs;
