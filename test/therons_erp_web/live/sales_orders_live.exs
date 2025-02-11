defmodule TheronsErpWeb.SalesOrdersLiveTest do
  use TheronsErpWeb.ConnCase

 @new_args %{ "_target" => ["sales_order", "sales_lines", "2", "product_id"],
   "line_id" => "2",
   "product_id" => "fa68f48a-a852-49fd-a80e-41592e9922a3",
   "sales_order" => %{
     "sales_lines" => %{
       "0" => %{
         "_form_type" => "update",
         "_persistent_id" => "0",
         "_touched" => "_form_type,_persistent_id,_touched,_unused_product_id_text_input,_unused_quantity,_unused_sales_price,_unused_total_price,_unused_unit_price,id,product_id,product_id_text_input,quantity,sales_price,total_price,unit_price",
         "_unused_product_id_text_input" => "",
         "_unused_quantity" => "",
         "_unused_sales_price" => "",
         "_unused_total_price" => "",
         "_unused_unit_price" => "",
         "id" => "ceb0aedf-6ef4-4497-b820-d43aad073750",
         "product_id" => "961be52a-0ad5-4fdb-be76-0c86fdbcd4e4",
         "product_id_text_input" => "abc123",
         "quantity" => "2",
         "sales_price" => "3.0",
         "total_price" => "6.0",
         "unit_price" => "6.0"
       },
       "1" => %{
         "_form_type" => "update",
         "_persistent_id" => "1",
         "_touched" => "_form_type,_persistent_id,_touched,_unused_product_id_text_input,_unused_quantity,_unused_sales_price,_unused_total_price,_unused_unit_price,id,product_id,product_id_text_input,quantity,sales_price,total_price,unit_price",
         "_unused_product_id_text_input" => "",
         "_unused_quantity" => "",
         "_unused_sales_price" => "",
         "_unused_total_price" => "",
         "_unused_unit_price" => "",
         "id" => "cfdf8f66-0cf5-41cb-97be-ea8a8b308fc1",
         "product_id" => "d3d5df6a-1829-40db-a054-64b48b6fc512",
         "product_id_text_input" => "Bob The Builder 2",
         "quantity" => "2",
         "sales_price" => "3.0",
         "total_price" => "6.0",
         "unit_price" => "4.0"
       },
       "2" => %{
         "_form_type" => "create",
         "_persistent_id" => "2",
         "_touched" => "_form_type,_persistent_id,_touched,_unused_product_id_text_input,_unused_quantity,_unused_sales_price,_unused_total_price,_unused_unit_price,product_id,product_id_text_input,quantity,sales_price,total_price,unit_price",
         "_unused_product_id_text_input" => "",
         "_unused_quantity" => "",
         "_unused_sales_price" => "",
         "_unused_total_price" => "",
         "_unused_unit_price" => "",
         "product_id" => "fa68f48a-a852-49fd-a80e-41592e9922a3",
         "product_id_text_input" => "Create New",
         "quantity" => "",
         "sales_price" => "",
         "total_price" => "",
         "unit_price" => ""
       }
     }
   }
 }

  test "children from froms" do
    sales_order = Ash.create!(TheronsErp.Sales.SalesOrder)

    form = AshPhoenix.Form.for_update(sales_order, :update,
      as: "sales_order")

    form = AshPhoenix.Form.validate(form, @new_args)
    IO.inspect(form)
    assert length(form.forms.sales_lines) == 3
  end
end
