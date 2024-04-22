program MaxValueArray;
var
  numbers: array[1..10] of Integer;
  i, maxValue: Integer;
begin
  write("Enter 10 integer values:");
  for i := 1 to 10 do
  begin
    read(numbers[i]);
  end;
  maxValue := numbers[1];
  for i := 2 to 10 do
  begin
    if numbers[i] > maxValue then
    begin
      maxValue := numbers[i];
    end;
  end;
  write("The maximum value is: ");  
  write(maxValue);
end.