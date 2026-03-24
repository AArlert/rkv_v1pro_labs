module array_assignment;
  int arr1 [1:0][1:0] = '{'{1, 2}, '{3, 4}};
  int arr2 [0:1][0:1];
  int arr3 [2][2];
  initial begin
    arr2 = arr1;
    arr3 = arr1;
    $display("arr1 content is %p", arr1);
    $display("arr2 content is %p", arr2);
    $display("arr2 content is %p", arr3);
    foreach(arr1[i, j]) begin
      $display("arr1[%0d][%0d] = %0d", i, j, arr1[i][j]);
      $display("arr2[%0d][%0d] = %0d", i, j, arr2[i][j]);
      $display("arr3[%0d][%0d] = %0d", i, j, arr3[i][j]);
    end
  end

endmodule
