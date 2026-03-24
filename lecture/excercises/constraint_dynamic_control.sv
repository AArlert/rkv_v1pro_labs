module constraint_dynamic_control;
  typedef enum {LOW_ADDR, HIGH_ADDR} access_t;
  class packet;
    rand bit[7:0] addr;
    rand bit[7:0] data;
    access_t access;
    constraint cstr_common {
      addr[1:0] == 0;
      //if(access == LOW_ADDR) {
      //   addr[7] == 0; 
      //   data inside {[0:15]};
      //}
      //else {
      //   addr[7] == 1; 
      //   data inside {[16:$]};
      //}
    }

    constraint cstr_low_addr {
      addr[7] == 0; 
      data inside {[0:15]};
    }

    constraint cstr_high_addr {
      addr[7] == 1; 
      data inside {[16:$]};
    }

    function void pre_randomize();
      if(access == LOW_ADDR) begin
        cstr_low_addr.constraint_mode(1);
        cstr_high_addr.constraint_mode(0);
        $display("randomizition take cstr_low_addr effect!");
      end
      else begin
        cstr_low_addr.constraint_mode(0);
        cstr_high_addr.constraint_mode(1);
        $display("randomizition take cstr_high_addr effect!");
      end
    endfunction

    function void post_randomize();
      $display("current packet object task %s type access with %s", access, sprint());
    endfunction

    function string sprint();
      sprint = $sformatf("members list \n addr = %0d \n data = %0d ", addr, data);
    endfunction

    function new();
      cstr_high_addr.constraint_mode(0);
    endfunction

  endclass

  initial begin
    automatic packet p = new();
    repeat(10) begin
      p.access = HIGH_ADDR;
      void'(p.randomize());
    end
  end

endmodule
