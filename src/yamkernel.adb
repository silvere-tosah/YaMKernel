with Ada.Text_IO; use Ada.Text_IO;

procedure YamKernel is
   count : Integer := 0;
begin
   put ("YamKernel is starting");
   loop
      if count = 15 then
         exit;
      else
         count := 1;
         Put ('#');
         null;
      end if;
      count := 5;
   end loop;
end YamKernel;
