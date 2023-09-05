package pkg_lib;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `define info(MSG, VERBOSITY=UVM_LOW,ID=get_name()) `uvm_info(ID,MSG,VERBOSITY)
    `define sv_rand_check(r) do begin if (!(r)) begin `info("Randomization Failed") $finish; end end while (0)

    typedef enum int {DATA_PROC, SHIFT, PACK} instr_group_t;
    typedef enum int
    {
        /*DATA PROCESS*/ ADC,  ADD,  ADR, AND, BIC, CMP,
        /*SHIFT*/        ASR,  LSL,  LSR,
        /*PACK_UNPACK*/  SXTB, SXTH, UXTB
    } instr_t;

    class instr_item extends uvm_object;

        rand instr_group_t instr_group;
        rand instr_t       instr;

        instr_t data_proc_q[$] = {ADC,  ADD,  ADR, AND, BIC, CMP};
        instr_t shift_q[$]     = {ASR, LSL, LSR};
        instr_t pack_q[$]      = {SXTB, SXTH, UXTB};

        static int data_proc_cnt;
        static int shift_cnt;
        static int pack_cnt;
        static int total_cnt;

        constraint inster_c {
            
            // Choose instruction from group
            if (instr_group==DATA_PROC) {
                instr inside {data_proc_q};
            }
            else if (instr_group==SHIFT) {
                instr inside {shift_q};
            }
            else {
                instr inside {pack_q};
            }
           
            // Apply variable ordering
            solve instr_group before instr;
        }

        `uvm_object_utils_begin(instr_item)
            `uvm_field_enum(instr_group_t, instr_group, UVM_DEFAULT)
            `uvm_field_enum(instr_t, instr, UVM_DEFAULT)
        `uvm_object_utils_end

        function new (string name="instr_item");
            super.new(name);
        endfunction

        function void post_randomize();
            if (instr inside {data_proc_q}) begin
                data_proc_cnt++;
                total_cnt++;
            end
            else if (instr inside {shift_q}) begin
                shift_cnt++;
                total_cnt++;
            end
            else begin
                pack_cnt++;
                total_cnt++;
            end
        endfunction : post_randomize

        function string convert2string ();
            return $sformatf("For item: %s, inster_group: %s, instr: %s",get_name(), instr_group.name(), instr.name());
        endfunction

    endclass

    class solve_before_test extends uvm_test;

        rand instr_item instr;

        `uvm_component_utils(solve_before_test)

        function new (string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        task run_phase (uvm_phase phase);
            super.run_phase(phase);
            for(int idx=0; idx<1200; idx++) begin
                instr=instr_item::type_id::create($sformatf("instr[%0d]",idx),this);
                `sv_rand_check(instr.randomize());
            end
        endtask

        function void final_phase (uvm_phase phase);
            string s="\n";
            $sformat(s,"%s\n**********************************************************************************\n",s);
            $sformat(s,"%s Total number of data process instructions: %0d, percent from total: %9.3f\n",s, instr.data_proc_cnt, 100 * instr.data_proc_cnt/instr.total_cnt);
            $sformat(s,"%s Total number of shift        instructions: %0d, percent from total: %9.3f\n",s, instr.shift_cnt, 100 * instr.shift_cnt/instr.total_cnt);
            $sformat(s,"%s Total number of pack unpack  instructions: %0d, percent from total: %9.3f\n",s, instr.pack_cnt, 100 * instr.pack_cnt/instr.total_cnt);
            $sformat(s,"%s***********************************************************************************\n",s);
            `info(s)
        endfunction

    endclass

endpackage

module top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import pkg_lib::*;
    initial run_test("solve_before_test");
endmodule
