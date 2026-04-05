using System;
using System.Data;
using System.Data.SqlClient;
using System.Windows;
using System.Windows.Controls;

namespace ECommerceWPF
{
    public partial class MainWindow : Window
    {
        private string connectionString = @"Server=DESKTOP-8A765R4\SQLEXPRESS;Database=ECommerceOMS;Trusted_Connection=True;";
        private int loggedInUserId = 0;
        private string loggedInUserName = "";
        private string loggedInUserRole = "";

        public MainWindow()
        {
            InitializeComponent();
        }

        private void ShowMessage(string message, bool isError)
        {
            lblMessage.Text = message;
            lblMessage.Foreground = isError ? System.Windows.Media.Brushes.Red : System.Windows.Media.Brushes.Green;
        }

        private void LoadData(string query, string title)
        {
            try
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    SqlDataAdapter adapter = new SqlDataAdapter(query, conn);
                    DataTable dt = new DataTable();
                    adapter.Fill(dt);
                    dataGrid.ItemsSource = dt.DefaultView;
                    lblPanelTitle.Text = title;
                    ShowMessage($"Loaded {dt.Rows.Count} records", false);
                }
            }
            catch (Exception ex)
            {
                ShowMessage($"Error: {ex.Message}", true);
            }
        }

        private int GetNextId(string tableName, string idColumn)
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                SqlCommand cmd = new SqlCommand($"SELECT ISNULL(MAX({idColumn}), 0) + 1 FROM {tableName}", conn);
                return (int)cmd.ExecuteScalar();
            }
        }

        // =========================================================
        // LOGIN
        // =========================================================

        private void BtnLogin_Click(object sender, RoutedEventArgs e)
        {
            string email = txtEmail.Text.Trim();
            string password = txtPassword.Password;
            string role = (cmbRole.SelectedItem as ComboBoxItem)?.Content.ToString();

            if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(password))
            {
                ShowMessage("Please enter email and password", true);
                return;
            }

            if (role == "Admin")
            {
                if (email == "admin@ecommerce.com" && password == "admin123")
                {
                    loggedInUserId = 0;
                    loggedInUserName = "Administrator";
                    loggedInUserRole = "admin";
                    ShowMessage("Welcome Administrator!", false);
                    ShowAdminUI();
                }
                else
                {
                    ShowMessage("Invalid admin credentials! Use: admin@ecommerce.com / admin123", true);
                }
            }
            else
            {
                try
                {
                    using (SqlConnection conn = new SqlConnection(connectionString))
                    {
                        conn.Open();
                        string query = "SELECT CustomerID, FirstName, LastName, IsActive FROM CUSTOMER WHERE Email = @Email AND Password = @Password";
                        SqlCommand cmd = new SqlCommand(query, conn);
                        cmd.Parameters.AddWithValue("@Email", email);
                        cmd.Parameters.AddWithValue("@Password", password);

                        SqlDataReader reader = cmd.ExecuteReader();
                        if (reader.Read())
                        {
                            if (reader["IsActive"].ToString() != "true")
                            {
                                ShowMessage("Account is deactivated!", true);
                                reader.Close();
                                return;
                            }

                            loggedInUserId = (int)reader["CustomerID"];
                            loggedInUserName = reader["FirstName"] + " " + reader["LastName"];
                            loggedInUserRole = "customer";
                            reader.Close();

                            ShowMessage($"Welcome back, {loggedInUserName}!", false);
                            ShowCustomerUI();
                        }
                        else
                        {
                            ShowMessage("Invalid email or password!", true);
                        }
                    }
                }
                catch (Exception ex)
                {
                    ShowMessage($"Login error: {ex.Message}", true);
                }
            }
        }

        private void BtnSignUp_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new Window
            {
                Title = "Customer Sign Up",
                Width = 380,
                Height = 500,
                WindowStartupLocation = WindowStartupLocation.CenterOwner,
                Owner = this
            };

            var panel = new StackPanel { Margin = new Thickness(10) };

            panel.Children.Add(new TextBlock { Text = "First Name:" });
            var txtFirstName = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtFirstName);

            panel.Children.Add(new TextBlock { Text = "Last Name:" });
            var txtLastName = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtLastName);

            panel.Children.Add(new TextBlock { Text = "Email:" });
            var txtEmail = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtEmail);

            panel.Children.Add(new TextBlock { Text = "Password:" });
            var txtPassword = new PasswordBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtPassword);

            panel.Children.Add(new TextBlock { Text = "Street (optional):" });
            var txtStreet = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtStreet);

            panel.Children.Add(new TextBlock { Text = "City (optional):" });
            var txtCity = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtCity);

            panel.Children.Add(new TextBlock { Text = "State (optional):" });
            var txtState = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtState);

            panel.Children.Add(new TextBlock { Text = "Zip Code (optional):" });
            var txtZip = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtZip);

            panel.Children.Add(new TextBlock { Text = "Country (optional):" });
            var txtCountry = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtCountry);

            panel.Children.Add(new TextBlock { Text = "Phone (optional):" });
            var txtPhone = new TextBox { Margin = new Thickness(0, 2, 0, 10) };
            panel.Children.Add(txtPhone);

            var btnSubmit = new Button { Content = "Sign Up", Background = System.Windows.Media.Brushes.Green, Foreground = System.Windows.Media.Brushes.White, Height = 30 };
            panel.Children.Add(btnSubmit);

            var lblMsg = new TextBlock { Margin = new Thickness(0, 10, 0, 0) };
            panel.Children.Add(lblMsg);

            dialog.Content = panel;

            btnSubmit.Click += (s, args) =>
            {
                if (string.IsNullOrEmpty(txtFirstName.Text) || string.IsNullOrEmpty(txtLastName.Text) ||
                    string.IsNullOrEmpty(txtEmail.Text) || string.IsNullOrEmpty(txtPassword.Password))
                {
                    lblMsg.Text = "First Name, Last Name, Email and Password are required!";
                    return;
                }

                try
                {
                    using (SqlConnection conn = new SqlConnection(connectionString))
                    {
                        conn.Open();
                        int nextId = GetNextId("CUSTOMER", "CustomerID");
                        string regDate = DateTime.Now.ToString("yyyy-MM-dd");

                        string query = @"INSERT INTO CUSTOMER (CustomerID, Email, Password, FirstName, LastName, Street, City, State, ZipCode, Country, RegistrationDate, IsActive, CreatedAt)
                                         VALUES (@CustomerID, @Email, @Password, @FirstName, @LastName, @Street, @City, @State, @ZipCode, @Country, @RegDate, 'true', @CreatedAt)";

                        SqlCommand cmd = new SqlCommand(query, conn);
                        cmd.Parameters.AddWithValue("@CustomerID", nextId);
                        cmd.Parameters.AddWithValue("@Email", txtEmail.Text);
                        cmd.Parameters.AddWithValue("@Password", txtPassword.Password);
                        cmd.Parameters.AddWithValue("@FirstName", txtFirstName.Text);
                        cmd.Parameters.AddWithValue("@LastName", txtLastName.Text);
                        cmd.Parameters.AddWithValue("@Street", string.IsNullOrEmpty(txtStreet.Text) ? (object)DBNull.Value : txtStreet.Text);
                        cmd.Parameters.AddWithValue("@City", string.IsNullOrEmpty(txtCity.Text) ? (object)DBNull.Value : txtCity.Text);
                        cmd.Parameters.AddWithValue("@State", string.IsNullOrEmpty(txtState.Text) ? (object)DBNull.Value : txtState.Text);
                        cmd.Parameters.AddWithValue("@ZipCode", string.IsNullOrEmpty(txtZip.Text) ? (object)DBNull.Value : txtZip.Text);
                        cmd.Parameters.AddWithValue("@Country", string.IsNullOrEmpty(txtCountry.Text) ? (object)DBNull.Value : txtCountry.Text);
                        cmd.Parameters.AddWithValue("@RegDate", regDate);
                        cmd.Parameters.AddWithValue("@CreatedAt", regDate);
                        cmd.ExecuteNonQuery();

                        if (!string.IsNullOrEmpty(txtPhone.Text))
                        {
                            SqlCommand cmdPhone = new SqlCommand("INSERT INTO CUSTOMER_PHONE (Phone, CustomerID) VALUES (@Phone, @CustomerID)", conn);
                            cmdPhone.Parameters.AddWithValue("@Phone", txtPhone.Text);
                            cmdPhone.Parameters.AddWithValue("@CustomerID", nextId);
                            cmdPhone.ExecuteNonQuery();
                        }

                        lblMsg.Text = $"Sign up successful! Your Customer ID is {nextId}. You can now login.";
                        lblMsg.Foreground = System.Windows.Media.Brushes.Green;
                    }
                }
                catch (Exception ex)
                {
                    lblMsg.Text = $"Error: {ex.Message}";
                    lblMsg.Foreground = System.Windows.Media.Brushes.Red;
                }
            };

            dialog.ShowDialog();
        }

        private void BtnLogout_Click(object sender, RoutedEventArgs e)
        {
            loggedInUserId = 0;
            loggedInUserName = "";
            loggedInUserRole = "";

            txtEmail.Text = "";
            txtPassword.Password = "";

            btnLogout.IsEnabled = false;
            menuPanel.Visibility = Visibility.Collapsed;
            customerMenu.Visibility = Visibility.Collapsed;
            adminMenu.Visibility = Visibility.Collapsed;

            dataGrid.ItemsSource = null;
            lblUserName.Text = "Not logged in";
            lblPanelTitle.Text = "Welcome";
            ShowMessage("Logged out successfully!", false);
        }

        private void ShowCustomerUI()
        {
            lblUserName.Text = $"Logged in as: {loggedInUserName} (Customer)";
            btnLogout.IsEnabled = true;
            menuPanel.Visibility = Visibility.Visible;
            customerMenu.Visibility = Visibility.Visible;
            adminMenu.Visibility = Visibility.Collapsed;
            lblMenuTitle.Text = "CUSTOMER MENU";
        }

        private void ShowAdminUI()
        {
            lblUserName.Text = $"Logged in as: {loggedInUserName} (Admin)";
            btnLogout.IsEnabled = true;
            menuPanel.Visibility = Visibility.Visible;
            customerMenu.Visibility = Visibility.Collapsed;
            adminMenu.Visibility = Visibility.Visible;
            lblMenuTitle.Text = "ADMIN MENU";
        }

        // =========================================================
        // CUSTOMER METHODS
        // =========================================================

        private void BtnBrowseProducts_Click(object sender, RoutedEventArgs e)
        {
            LoadData("SELECT ProductID, ProductName, Price, Stock FROM PRODUCTS ORDER BY ProductID", "All Products");
        }

        private void BtnSearchCategory_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new Window
            {
                Title = "Search by Category",
                Width = 350,
                Height = 200,
                WindowStartupLocation = WindowStartupLocation.CenterOwner,
                Owner = this
            };

            var panel = new StackPanel { Margin = new Thickness(10) };

            // Show categories first
            panel.Children.Add(new TextBlock { Text = "Available Categories:", FontWeight = FontWeights.Bold });
            try
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("SELECT CategoryID, CategoryName FROM CATEGORY", conn);
                    SqlDataReader reader = cmd.ExecuteReader();
                    while (reader.Read())
                    {
                        panel.Children.Add(new TextBlock { Text = $"  {reader["CategoryID"]} - {reader["CategoryName"]}", Margin = new Thickness(0, 2, 0, 2) });
                    }
                    reader.Close();
                }
            }
            catch (Exception ex)
            {
                panel.Children.Add(new TextBlock { Text = $"Error: {ex.Message}", Foreground = System.Windows.Media.Brushes.Red });
            }

            panel.Children.Add(new TextBlock { Text = "Enter Category ID:", Margin = new Thickness(0, 10, 0, 5) });
            var txtCatId = new TextBox { Margin = new Thickness(0, 2, 0, 10) };
            panel.Children.Add(txtCatId);

            var btnSearch = new Button { Content = "Search", Height = 30 };
            panel.Children.Add(btnSearch);

            dialog.Content = panel;

            btnSearch.Click += (s, args) =>
            {
                if (int.TryParse(txtCatId.Text, out int catId))
                {
                    LoadData($@"SELECT p.ProductID, p.ProductName, p.Price, p.Stock 
                                FROM PRODUCTS p WHERE p.CategoryID = {catId}", $"Products in Category {catId}");
                    dialog.Close();
                }
                else
                {
                    MessageBox.Show("Invalid Category ID!");
                }
            };

            dialog.ShowDialog();
        }

        private void BtnAddToCart_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new Window
            {
                Title = "Add to Cart",
                Width = 350,
                Height = 250,
                WindowStartupLocation = WindowStartupLocation.CenterOwner,
                Owner = this
            };

            var panel = new StackPanel { Margin = new Thickness(10) };

            panel.Children.Add(new TextBlock { Text = "Product ID:" });
            var txtProductId = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtProductId);

            panel.Children.Add(new TextBlock { Text = "Quantity:" });
            var txtQuantity = new TextBox { Text = "1", Margin = new Thickness(0, 2, 0, 10) };
            panel.Children.Add(txtQuantity);

            var btnAdd = new Button { Content = "Add to Cart", Height = 30, Background = System.Windows.Media.Brushes.Green, Foreground = System.Windows.Media.Brushes.White };
            panel.Children.Add(btnAdd);

            var lblMsg = new TextBlock { Margin = new Thickness(0, 10, 0, 0) };
            panel.Children.Add(lblMsg);

            dialog.Content = panel;

            btnAdd.Click += (s, args) =>
            {
                if (!int.TryParse(txtProductId.Text, out int productId))
                {
                    lblMsg.Text = "Invalid Product ID!";
                    return;
                }
                if (!int.TryParse(txtQuantity.Text, out int quantity) || quantity <= 0)
                {
                    lblMsg.Text = "Invalid Quantity!";
                    return;
                }

                try
                {
                    using (SqlConnection conn = new SqlConnection(connectionString))
                    {
                        conn.Open();

                        SqlCommand getCart = new SqlCommand("SELECT CartID FROM CART WHERE CustomerID = @CustomerID", conn);
                        getCart.Parameters.AddWithValue("@CustomerID", loggedInUserId);
                        object cartResult = getCart.ExecuteScalar();

                        int cartId;
                        if (cartResult == null)
                        {
                            cartId = GetNextId("CART", "CartID");
                            SqlCommand createCart = new SqlCommand("INSERT INTO CART (CartID, CreatedAt, CustomerID) VALUES (@CartID, @CreatedAt, @CustomerID)", conn);
                            createCart.Parameters.AddWithValue("@CartID", cartId);
                            createCart.Parameters.AddWithValue("@CreatedAt", DateTime.Now.ToString("yyyy-MM-dd"));
                            createCart.Parameters.AddWithValue("@CustomerID", loggedInUserId);
                            createCart.ExecuteNonQuery();
                        }
                        else
                        {
                            cartId = (int)cartResult;
                        }

                        SqlCommand checkItem = new SqlCommand("SELECT Quantity FROM CARTITEM WHERE CartID = @CartID AND ProductID = @ProductID", conn);
                        checkItem.Parameters.AddWithValue("@CartID", cartId);
                        checkItem.Parameters.AddWithValue("@ProductID", productId);
                        object existingQty = checkItem.ExecuteScalar();

                        if (existingQty != null)
                        {
                            int newQty = (int)existingQty + quantity;
                            SqlCommand updateItem = new SqlCommand("UPDATE CARTITEM SET Quantity = @Quantity WHERE CartID = @CartID AND ProductID = @ProductID", conn);
                            updateItem.Parameters.AddWithValue("@Quantity", newQty);
                            updateItem.Parameters.AddWithValue("@CartID", cartId);
                            updateItem.Parameters.AddWithValue("@ProductID", productId);
                            updateItem.ExecuteNonQuery();
                            lblMsg.Text = $"Updated! New quantity: {newQty}";
                        }
                        else
                        {
                            int itemId = GetNextId("CARTITEM", "CartItemID");
                            SqlCommand insertItem = new SqlCommand("INSERT INTO CARTITEM (CartItemID, Quantity, AddedAt, ProductID, CartID) VALUES (@ItemID, @Quantity, @AddedAt, @ProductID, @CartID)", conn);
                            insertItem.Parameters.AddWithValue("@ItemID", itemId);
                            insertItem.Parameters.AddWithValue("@Quantity", quantity);
                            insertItem.Parameters.AddWithValue("@AddedAt", DateTime.Now.ToString("yyyy-MM-dd"));
                            insertItem.Parameters.AddWithValue("@ProductID", productId);
                            insertItem.Parameters.AddWithValue("@CartID", cartId);
                            insertItem.ExecuteNonQuery();
                            lblMsg.Text = $"Product added! Quantity: {quantity}";
                        }
                        lblMsg.Foreground = System.Windows.Media.Brushes.Green;
                    }
                }
                catch (Exception ex)
                {
                    lblMsg.Text = $"Error: {ex.Message}";
                    lblMsg.Foreground = System.Windows.Media.Brushes.Red;
                }
            };

            dialog.ShowDialog();
        }

        private void BtnViewCart_Click(object sender, RoutedEventArgs e)
        {
            LoadData($@"
                SELECT p.ProductID, p.ProductName, p.Price, ci.Quantity, (p.Price * ci.Quantity) AS Subtotal
                FROM CARTITEM ci 
                INNER JOIN PRODUCTS p ON ci.ProductID = p.ProductID
                INNER JOIN CART c ON ci.CartID = c.CartID
                WHERE c.CustomerID = {loggedInUserId}", "My Cart");
        }

        private void BtnPlaceOrder_Click(object sender, RoutedEventArgs e)
        {
            // Get cart items
            DataTable cartItems = null;
            try
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    SqlDataAdapter adapter = new SqlDataAdapter($@"
                        SELECT ci.ProductID, ci.Quantity, p.Price 
                        FROM CARTITEM ci 
                        INNER JOIN CART c ON ci.CartID = c.CartID
                        INNER JOIN PRODUCTS p ON ci.ProductID = p.ProductID
                        WHERE c.CustomerID = {loggedInUserId}", conn);
                    cartItems = new DataTable();
                    adapter.Fill(cartItems);
                }
            }
            catch (Exception ex)
            {
                ShowMessage($"Error loading cart: {ex.Message}", true);
                return;
            }

            if (cartItems.Rows.Count == 0)
            {
                ShowMessage("Your cart is empty!", true);
                return;
            }

            // Calculate total
            decimal total = 0;
            foreach (DataRow row in cartItems.Rows)
            {
                total += (decimal)row["Price"] * (int)row["Quantity"];
            }

            var dialog = new Window
            {
                Title = "Place Order",
                Width = 450,
                Height = 500,
                WindowStartupLocation = WindowStartupLocation.CenterOwner,
                Owner = this
            };

            var scrollPanel = new ScrollViewer();
            var panel = new StackPanel { Margin = new Thickness(10) };

            // Order summary
            panel.Children.Add(new TextBlock { Text = "ORDER SUMMARY", FontWeight = FontWeights.Bold, FontSize = 14, Margin = new Thickness(0, 0, 0, 10) });
            foreach (DataRow row in cartItems.Rows)
            {
                panel.Children.Add(new TextBlock { Text = $"Product {row["ProductID"]} x {row["Quantity"]} = ${(decimal)row["Price"] * (int)row["Quantity"]}", Margin = new Thickness(0, 2, 0, 2) });
            }
            panel.Children.Add(new TextBlock { Text = $"TOTAL: ${total}", FontWeight = FontWeights.Bold, Margin = new Thickness(0, 10, 0, 15) });

            // Shipping address
            panel.Children.Add(new TextBlock { Text = "SHIPPING ADDRESS", FontWeight = FontWeights.Bold, Margin = new Thickness(0, 0, 0, 5) });
            panel.Children.Add(new TextBlock { Text = "Street:" });
            var txtStreet = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtStreet);
            panel.Children.Add(new TextBlock { Text = "City:" });
            var txtCity = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtCity);
            panel.Children.Add(new TextBlock { Text = "State:" });
            var txtState = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtState);
            panel.Children.Add(new TextBlock { Text = "Zip Code:" });
            var txtZip = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtZip);
            panel.Children.Add(new TextBlock { Text = "Country:" });
            var txtCountry = new TextBox { Margin = new Thickness(0, 2, 0, 15) };
            panel.Children.Add(txtCountry);

            // Payment
            panel.Children.Add(new TextBlock { Text = "PAYMENT METHOD", FontWeight = FontWeights.Bold, Margin = new Thickness(0, 0, 0, 5) });
            var cmbPayment = new ComboBox { Margin = new Thickness(0, 2, 0, 15) };
            cmbPayment.Items.Add("Credit Card");
            cmbPayment.Items.Add("PayPal");
            cmbPayment.Items.Add("Debit Card");
            cmbPayment.SelectedIndex = 0;
            panel.Children.Add(cmbPayment);

            var btnPlace = new Button { Content = "PLACE ORDER", Height = 35, Background = System.Windows.Media.Brushes.Green, Foreground = System.Windows.Media.Brushes.White, FontWeight = FontWeights.Bold };
            panel.Children.Add(btnPlace);

            var lblMsg = new TextBlock { Margin = new Thickness(0, 10, 0, 0) };
            panel.Children.Add(lblMsg);

            scrollPanel.Content = panel;
            dialog.Content = scrollPanel;

            btnPlace.Click += (s, args) =>
            {
                if (string.IsNullOrEmpty(txtStreet.Text) || string.IsNullOrEmpty(txtCity.Text) || string.IsNullOrEmpty(txtCountry.Text))
                {
                    lblMsg.Text = "Street, City and Country are required!";
                    return;
                }

                try
                {
                    using (SqlConnection conn = new SqlConnection(connectionString))
                    {
                        conn.Open();

                        // Get cart ID
                        SqlCommand getCartId = new SqlCommand($"SELECT CartID FROM CART WHERE CustomerID = {loggedInUserId}", conn);
                        int cartId = (int)getCartId.ExecuteScalar();

                        // Create order
                        int newOrderId = GetNextId("ORDERS", "OrderID");
                        string orderDate = DateTime.Now.ToString("yyyy-MM-dd");
                        string transactionRef = "TXN-" + DateTime.Now.Ticks.ToString();

                        SqlTransaction transaction = conn.BeginTransaction();

                        try
                        {
                            // Insert Order
                            SqlCommand insertOrder = new SqlCommand(@"
                                INSERT INTO ORDERS (OrderID, OrderDate, Status, Street, City, State, ZipCode, Country, CreatedAt, CustomerID)
                                VALUES (@OrderID, @OrderDate, 'Confirmed', @Street, @City, @State, @ZipCode, @Country, @CreatedAt, @CustomerID)", conn, transaction);
                            insertOrder.Parameters.AddWithValue("@OrderID", newOrderId);
                            insertOrder.Parameters.AddWithValue("@OrderDate", orderDate);
                            insertOrder.Parameters.AddWithValue("@Street", txtStreet.Text);
                            insertOrder.Parameters.AddWithValue("@City", txtCity.Text);
                            insertOrder.Parameters.AddWithValue("@State", txtState.Text);
                            insertOrder.Parameters.AddWithValue("@ZipCode", txtZip.Text);
                            insertOrder.Parameters.AddWithValue("@Country", txtCountry.Text);
                            insertOrder.Parameters.AddWithValue("@CreatedAt", orderDate);
                            insertOrder.Parameters.AddWithValue("@CustomerID", loggedInUserId);
                            insertOrder.ExecuteNonQuery();

                            // Insert Order Items
                            int nextItemId = GetNextId("ORDERITEM", "OrderItemID");
                            foreach (DataRow row in cartItems.Rows)
                            {
                                nextItemId++;
                                SqlCommand insertItem = new SqlCommand(@"
                                    INSERT INTO ORDERITEM (OrderItemID, Quantity, UnitPrice, ProductID, OrderID)
                                    VALUES (@OrderItemID, @Quantity, @UnitPrice, @ProductID, @OrderID)", conn, transaction);
                                insertItem.Parameters.AddWithValue("@OrderItemID", nextItemId);
                                insertItem.Parameters.AddWithValue("@Quantity", (int)row["Quantity"]);
                                insertItem.Parameters.AddWithValue("@UnitPrice", (decimal)row["Price"]);
                                insertItem.Parameters.AddWithValue("@ProductID", (int)row["ProductID"]);
                                insertItem.Parameters.AddWithValue("@OrderID", newOrderId);
                                insertItem.ExecuteNonQuery();
                            }

                            // Insert Payment
                            int paymentId = GetNextId("PAYMENT", "PaymentID");
                            SqlCommand insertPayment = new SqlCommand(@"
                                INSERT INTO PAYMENT (PaymentID, PaymentMethod, Amount, Status, TransactionRef, PaymentDate, CreatedAt, OrderID)
                                VALUES (@PaymentID, @PaymentMethod, @Amount, 'Paid', @TransactionRef, @PaymentDate, @CreatedAt, @OrderID)", conn, transaction);
                            insertPayment.Parameters.AddWithValue("@PaymentID", paymentId);
                            insertPayment.Parameters.AddWithValue("@PaymentMethod", cmbPayment.SelectedItem.ToString());
                            insertPayment.Parameters.AddWithValue("@Amount", total);
                            insertPayment.Parameters.AddWithValue("@TransactionRef", transactionRef);
                            insertPayment.Parameters.AddWithValue("@PaymentDate", orderDate);
                            insertPayment.Parameters.AddWithValue("@CreatedAt", orderDate);
                            insertPayment.Parameters.AddWithValue("@OrderID", newOrderId);
                            insertPayment.ExecuteNonQuery();

                            // Insert Shipment
                            int shipmentId = GetNextId("SHIPMENT", "ShipmentID");
                            SqlCommand insertShipment = new SqlCommand(@"
                                INSERT INTO SHIPMENT (ShipmentID, Street, City, State, ZipCode, Country, Status, CreatedAt, OrderID)
                                VALUES (@ShipmentID, @Street, @City, @State, @ZipCode, @Country, 'Processing', @CreatedAt, @OrderID)", conn, transaction);
                            insertShipment.Parameters.AddWithValue("@ShipmentID", shipmentId);
                            insertShipment.Parameters.AddWithValue("@Street", txtStreet.Text);
                            insertShipment.Parameters.AddWithValue("@City", txtCity.Text);
                            insertShipment.Parameters.AddWithValue("@State", txtState.Text);
                            insertShipment.Parameters.AddWithValue("@ZipCode", txtZip.Text);
                            insertShipment.Parameters.AddWithValue("@Country", txtCountry.Text);
                            insertShipment.Parameters.AddWithValue("@CreatedAt", orderDate);
                            insertShipment.Parameters.AddWithValue("@OrderID", newOrderId);
                            insertShipment.ExecuteNonQuery();

                            // Clear Cart
                            SqlCommand clearCart = new SqlCommand($"DELETE FROM CARTITEM WHERE CartID = {cartId}", conn, transaction);
                            clearCart.ExecuteNonQuery();

                            transaction.Commit();

                            lblMsg.Text = $"ORDER PLACED SUCCESSFULLY!\nOrder ID: {newOrderId}\nTotal: ${total}";
                            lblMsg.Foreground = System.Windows.Media.Brushes.Green;

                            // Refresh cart view
                            BtnViewCart_Click(null, null);

                            System.Threading.Tasks.Task.Delay(3000).ContinueWith(_ =>
                            {
                                Dispatcher.Invoke(() => dialog.Close());
                            });
                        }
                        catch (Exception ex)
                        {
                            transaction.Rollback();
                            throw ex;
                        }
                    }
                }
                catch (Exception ex)
                {
                    lblMsg.Text = $"Error: {ex.Message}";
                    lblMsg.Foreground = System.Windows.Media.Brushes.Red;
                }
            };

            dialog.ShowDialog();
        }

        private void BtnMyOrders_Click(object sender, RoutedEventArgs e)
        {
            LoadData($@"
                SELECT o.OrderID, o.OrderDate, o.Status, 
                       (SELECT SUM(oi.Quantity * oi.UnitPrice) FROM ORDERITEM oi WHERE oi.OrderID = o.OrderID) AS TotalAmount,
                       ISNULL(p.Status, 'Not Paid') AS PaymentStatus, 
                       ISNULL(s.TrackingNumber, 'Not Assigned') AS TrackingNumber
                FROM ORDERS o
                LEFT JOIN PAYMENT p ON o.OrderID = p.OrderID
                LEFT JOIN SHIPMENT s ON o.OrderID = s.OrderID
                WHERE o.CustomerID = {loggedInUserId}
                ORDER BY o.OrderID DESC", "My Orders");
        }

        private void BtnMakePayment_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new Window
            {
                Title = "Make Payment",
                Width = 400,
                Height = 350,
                WindowStartupLocation = WindowStartupLocation.CenterOwner,
                Owner = this
            };

            var panel = new StackPanel { Margin = new Thickness(10) };

            // Load pending orders
            DataTable pendingOrders = new DataTable();
            try
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    SqlDataAdapter adapter = new SqlDataAdapter($@"
                        SELECT o.OrderID, o.OrderDate,
                               (SELECT SUM(oi.Quantity * oi.UnitPrice) FROM ORDERITEM oi WHERE oi.OrderID = o.OrderID) AS TotalAmount
                        FROM ORDERS o
                        WHERE o.CustomerID = {loggedInUserId}
                          AND o.Status != 'Delivered'
                          AND o.Status != 'Cancelled'
                          AND o.OrderID NOT IN (SELECT OrderID FROM PAYMENT WHERE Status = 'Paid')
                        ORDER BY o.OrderID DESC", conn);
                    adapter.Fill(pendingOrders);
                }
            }
            catch (Exception ex)
            {
                ShowMessage($"Error: {ex.Message}", true);
                return;
            }

            if (pendingOrders.Rows.Count == 0)
            {
                MessageBox.Show("No pending payments found!", "Information", MessageBoxButton.OK, MessageBoxImage.Information);
                return;
            }

            panel.Children.Add(new TextBlock { Text = "Select Order to Pay:", FontWeight = FontWeights.Bold });
            var cmbOrder = new ComboBox { Margin = new Thickness(0, 5, 0, 10) };
            foreach (DataRow row in pendingOrders.Rows)
            {
                cmbOrder.Items.Add($"Order {row["OrderID"]} - {Convert.ToDateTime(row["OrderDate"]).ToShortDateString()} - ${row["TotalAmount"]}");
            }
            cmbOrder.SelectedIndex = 0;
            panel.Children.Add(cmbOrder);

            panel.Children.Add(new TextBlock { Text = "Payment Method:" });
            var cmbPayment = new ComboBox { Margin = new Thickness(0, 5, 0, 10) };
            cmbPayment.Items.Add("Credit Card");
            cmbPayment.Items.Add("PayPal");
            cmbPayment.Items.Add("Debit Card");
            cmbPayment.SelectedIndex = 0;
            panel.Children.Add(cmbPayment);

            panel.Children.Add(new TextBlock { Text = "Card Number:" });
            var txtCard = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtCard);

            panel.Children.Add(new TextBlock { Text = "Expiry Date (MM/YY):" });
            var txtExpiry = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtExpiry);

            panel.Children.Add(new TextBlock { Text = "CVV:" });
            var txtCvv = new TextBox { Margin = new Thickness(0, 2, 0, 10) };
            panel.Children.Add(txtCvv);

            var btnPay = new Button { Content = "PAY NOW", Height = 35, Background = System.Windows.Media.Brushes.Green, Foreground = System.Windows.Media.Brushes.White, FontWeight = FontWeights.Bold };
            panel.Children.Add(btnPay);

            var lblMsg = new TextBlock { Margin = new Thickness(0, 10, 0, 0) };
            panel.Children.Add(lblMsg);

            dialog.Content = panel;

            btnPay.Click += (s, args) =>
            {
                string selected = cmbOrder.SelectedItem.ToString();
                int orderId = int.Parse(selected.Split(' ')[1]);

                try
                {
                    using (SqlConnection conn = new SqlConnection(connectionString))
                    {
                        conn.Open();
                        string transactionRef = "TXN-" + DateTime.Now.Ticks.ToString();
                        string paymentDate = DateTime.Now.ToString("yyyy-MM-dd");

                        SqlCommand getTotal = new SqlCommand($"SELECT SUM(Quantity * UnitPrice) FROM ORDERITEM WHERE OrderID = {orderId}", conn);
                        decimal total = (decimal)getTotal.ExecuteScalar();

                        SqlCommand checkPayment = new SqlCommand($"SELECT COUNT(*) FROM PAYMENT WHERE OrderID = {orderId}", conn);
                        int paymentExists = (int)checkPayment.ExecuteScalar();

                        if (paymentExists > 0)
                        {
                            SqlCommand updatePayment = new SqlCommand($@"
                                UPDATE PAYMENT SET PaymentMethod = '{cmbPayment.SelectedItem}', Status = 'Paid', 
                                TransactionRef = '{transactionRef}', PaymentDate = '{paymentDate}'
                                WHERE OrderID = {orderId}", conn);
                            updatePayment.ExecuteNonQuery();
                        }
                        else
                        {
                            int paymentId = GetNextId("PAYMENT", "PaymentID");
                            SqlCommand insertPayment = new SqlCommand($@"
                                INSERT INTO PAYMENT (PaymentID, PaymentMethod, Amount, Status, TransactionRef, PaymentDate, CreatedAt, OrderID)
                                VALUES ({paymentId}, '{cmbPayment.SelectedItem}', {total}, 'Paid', '{transactionRef}', '{paymentDate}', '{paymentDate}', {orderId})", conn);
                            insertPayment.ExecuteNonQuery();
                        }

                        SqlCommand updateOrder = new SqlCommand($"UPDATE ORDERS SET Status = 'Confirmed' WHERE OrderID = {orderId}", conn);
                        updateOrder.ExecuteNonQuery();

                        lblMsg.Text = $"PAYMENT SUCCESSFUL!\nOrder ID: {orderId}\nAmount Paid: ${total}";
                        lblMsg.Foreground = System.Windows.Media.Brushes.Green;

                        BtnMyOrders_Click(null, null);

                        System.Threading.Tasks.Task.Delay(2000).ContinueWith(_ =>
                        {
                            Dispatcher.Invoke(() => dialog.Close());
                        });
                    }
                }
                catch (Exception ex)
                {
                    lblMsg.Text = $"Error: {ex.Message}";
                    lblMsg.Foreground = System.Windows.Media.Brushes.Red;
                }
            };

            dialog.ShowDialog();
        }

        private void BtnTrackShipment_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new Window
            {
                Title = "Track Shipment",
                Width = 400,
                Height = 250,
                WindowStartupLocation = WindowStartupLocation.CenterOwner,
                Owner = this
            };

            var panel = new StackPanel { Margin = new Thickness(10) };
            panel.Children.Add(new TextBlock { Text = "Enter Order ID:" });
            var txtOrderId = new TextBox { Margin = new Thickness(0, 5, 0, 10) };
            panel.Children.Add(txtOrderId);

            var btnTrack = new Button { Content = "Track", Height = 30 };
            panel.Children.Add(btnTrack);

            var lblResult = new TextBlock { Margin = new Thickness(0, 10, 0, 0), TextWrapping = TextWrapping.Wrap };
            panel.Children.Add(lblResult);

            dialog.Content = panel;

            btnTrack.Click += (s, args) =>
            {
                if (int.TryParse(txtOrderId.Text, out int orderId))
                {
                    try
                    {
                        using (SqlConnection conn = new SqlConnection(connectionString))
                        {
                            conn.Open();
                            SqlCommand cmd = new SqlCommand($@"
                                SELECT s.TrackingNumber, s.Carrier, s.Status, s.ShippedDate, s.DeliveredDate
                                FROM SHIPMENT s 
                                INNER JOIN ORDERS o ON s.OrderID = o.OrderID
                                WHERE s.OrderID = {orderId} AND o.CustomerID = {loggedInUserId}", conn);
                            SqlDataReader reader = cmd.ExecuteReader();

                            if (reader.Read())
                            {
                                lblResult.Text = $"Tracking Number: {reader["TrackingNumber"]?.ToString() ?? "Not assigned"}\n" +
                                                 $"Carrier: {reader["Carrier"]?.ToString() ?? "N/A"}\n" +
                                                 $"Status: {reader["Status"]}\n" +
                                                 (reader["ShippedDate"] != DBNull.Value ? $"Shipped Date: {Convert.ToDateTime(reader["ShippedDate"]).ToShortDateString()}\n" : "") +
                                                 (reader["DeliveredDate"] != DBNull.Value ? $"Delivered Date: {Convert.ToDateTime(reader["DeliveredDate"]).ToShortDateString()}" : "");
                                lblResult.Foreground = System.Windows.Media.Brushes.Green;
                            }
                            else
                            {
                                lblResult.Text = "No shipment found for this order.";
                                lblResult.Foreground = System.Windows.Media.Brushes.Red;
                            }
                            reader.Close();
                        }
                    }
                    catch (Exception ex)
                    {
                        lblResult.Text = $"Error: {ex.Message}";
                        lblResult.Foreground = System.Windows.Media.Brushes.Red;
                    }
                }
                else
                {
                    lblResult.Text = "Invalid Order ID!";
                    lblResult.Foreground = System.Windows.Media.Brushes.Red;
                }
            };

            dialog.ShowDialog();
        }

        private void BtnWriteReview_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new Window
            {
                Title = "Write Review",
                Width = 380,
                Height = 350,
                WindowStartupLocation = WindowStartupLocation.CenterOwner,
                Owner = this
            };

            var panel = new StackPanel { Margin = new Thickness(10) };

            panel.Children.Add(new TextBlock { Text = "Product ID:" });
            var txtProductId = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtProductId);

            panel.Children.Add(new TextBlock { Text = "Rating (1-5):" });
            var txtRating = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtRating);

            panel.Children.Add(new TextBlock { Text = "Comment:" });
            var txtComment = new TextBox { Height = 80, TextWrapping = TextWrapping.Wrap, Margin = new Thickness(0, 2, 0, 10) };
            panel.Children.Add(txtComment);

            var btnSubmit = new Button { Content = "Submit Review", Height = 35, Background = System.Windows.Media.Brushes.Green, Foreground = System.Windows.Media.Brushes.White };
            panel.Children.Add(btnSubmit);

            var lblMsg = new TextBlock { Margin = new Thickness(0, 10, 0, 0) };
            panel.Children.Add(lblMsg);

            dialog.Content = panel;

            btnSubmit.Click += (s, args) =>
            {
                if (!int.TryParse(txtProductId.Text, out int productId))
                {
                    lblMsg.Text = "Invalid Product ID!";
                    return;
                }
                if (!int.TryParse(txtRating.Text, out int rating) || rating < 1 || rating > 5)
                {
                    lblMsg.Text = "Rating must be 1-5!";
                    return;
                }

                try
                {
                    using (SqlConnection conn = new SqlConnection(connectionString))
                    {
                        conn.Open();
                        int reviewId = GetNextId("REVIEW", "ReviewID");
                        string reviewDate = DateTime.Now.ToString("yyyy-MM-dd");

                        SqlCommand cmd = new SqlCommand(@"
                            INSERT INTO REVIEW (ReviewID, Rating, Comment, ReviewDate, CreatedAt, CustomerID, ProductID)
                            VALUES (@ReviewID, @Rating, @Comment, @ReviewDate, @CreatedAt, @CustomerID, @ProductID)", conn);
                        cmd.Parameters.AddWithValue("@ReviewID", reviewId);
                        cmd.Parameters.AddWithValue("@Rating", rating);
                        cmd.Parameters.AddWithValue("@Comment", txtComment.Text);
                        cmd.Parameters.AddWithValue("@ReviewDate", reviewDate);
                        cmd.Parameters.AddWithValue("@CreatedAt", reviewDate);
                        cmd.Parameters.AddWithValue("@CustomerID", loggedInUserId);
                        cmd.Parameters.AddWithValue("@ProductID", productId);
                        cmd.ExecuteNonQuery();

                        lblMsg.Text = "Review submitted successfully!";
                        lblMsg.Foreground = System.Windows.Media.Brushes.Green;

                        System.Threading.Tasks.Task.Delay(1500).ContinueWith(_ =>
                        {
                            Dispatcher.Invoke(() => dialog.Close());
                        });
                    }
                }
                catch (Exception ex)
                {
                    lblMsg.Text = $"Error: {ex.Message}";
                    lblMsg.Foreground = System.Windows.Media.Brushes.Red;
                }
            };

            dialog.ShowDialog();
        }

        private void BtnMyProfile_Click(object sender, RoutedEventArgs e)
        {
            LoadData($"SELECT CustomerID, FirstName, LastName, Email, Street, City, State, ZipCode, Country, RegistrationDate FROM CUSTOMER WHERE CustomerID = {loggedInUserId}", "My Profile");
        }

        // =========================================================
        // ADMIN METHODS
        // =========================================================

        private void BtnAdminViewProducts_Click(object sender, RoutedEventArgs e)
        {
            LoadData(@"SELECT p.ProductID, p.ProductName, p.Price, p.Stock, p.CategoryID, c.CategoryName, s.SupplierName
                       FROM PRODUCTS p
                       INNER JOIN CATEGORY c ON p.CategoryID = c.CategoryID
                       INNER JOIN SUPPLIER s ON p.SupplierID = s.SupplierID
                       ORDER BY p.ProductID", "All Products (Admin)");
        }

        private void BtnAdminAddProduct_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new Window
            {
                Title = "Add Product",
                Width = 380,
                Height = 450,
                WindowStartupLocation = WindowStartupLocation.CenterOwner,
                Owner = this
            };

            var panel = new StackPanel { Margin = new Thickness(10) };
            panel.Children.Add(new TextBlock { Text = "Product Name:" });
            var txtName = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtName);

            panel.Children.Add(new TextBlock { Text = "Description:" });
            var txtDesc = new TextBox { Height = 60, TextWrapping = TextWrapping.Wrap, Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtDesc);

            panel.Children.Add(new TextBlock { Text = "Price:" });
            var txtPrice = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtPrice);

            panel.Children.Add(new TextBlock { Text = "Stock:" });
            var txtStock = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtStock);

            panel.Children.Add(new TextBlock { Text = "Category ID:" });
            var txtCatId = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtCatId);

            panel.Children.Add(new TextBlock { Text = "Supplier ID:" });
            var txtSuppId = new TextBox { Margin = new Thickness(0, 2, 0, 10) };
            panel.Children.Add(txtSuppId);

            var btnAdd = new Button { Content = "Add Product", Height = 35, Background = System.Windows.Media.Brushes.Green, Foreground = System.Windows.Media.Brushes.White };
            panel.Children.Add(btnAdd);

            var lblMsg = new TextBlock { Margin = new Thickness(0, 10, 0, 0) };
            panel.Children.Add(lblMsg);

            dialog.Content = panel;

            btnAdd.Click += (s, args) =>
            {
                if (string.IsNullOrEmpty(txtName.Text) || !decimal.TryParse(txtPrice.Text, out decimal price) || !int.TryParse(txtStock.Text, out int stock))
                {
                    lblMsg.Text = "Please fill all required fields correctly!";
                    return;
                }

                try
                {
                    using (SqlConnection conn = new SqlConnection(connectionString))
                    {
                        conn.Open();
                        int productId = GetNextId("PRODUCTS", "ProductID");
                        string createdAt = DateTime.Now.ToString("yyyy-MM-dd");

                        SqlCommand cmd = new SqlCommand(@"
                            INSERT INTO PRODUCTS (ProductID, ProductName, Description, Price, Stock, CreatedAt, CategoryID, SupplierID)
                            VALUES (@ProductID, @ProductName, @Description, @Price, @Stock, @CreatedAt, @CategoryID, @SupplierID)", conn);
                        cmd.Parameters.AddWithValue("@ProductID", productId);
                        cmd.Parameters.AddWithValue("@ProductName", txtName.Text);
                        cmd.Parameters.AddWithValue("@Description", string.IsNullOrEmpty(txtDesc.Text) ? (object)DBNull.Value : txtDesc.Text);
                        cmd.Parameters.AddWithValue("@Price", price);
                        cmd.Parameters.AddWithValue("@Stock", stock);
                        cmd.Parameters.AddWithValue("@CreatedAt", createdAt);
                        cmd.Parameters.AddWithValue("@CategoryID", int.Parse(txtCatId.Text));
                        cmd.Parameters.AddWithValue("@SupplierID", int.Parse(txtSuppId.Text));
                        cmd.ExecuteNonQuery();

                        lblMsg.Text = $"Product added successfully! ID: {productId}";
                        lblMsg.Foreground = System.Windows.Media.Brushes.Green;
                        BtnAdminViewProducts_Click(null, null);

                        System.Threading.Tasks.Task.Delay(1500).ContinueWith(_ =>
                        {
                            Dispatcher.Invoke(() => dialog.Close());
                        });
                    }
                }
                catch (Exception ex)
                {
                    lblMsg.Text = $"Error: {ex.Message}";
                    lblMsg.Foreground = System.Windows.Media.Brushes.Red;
                }
            };
            dialog.ShowDialog();
        }

        private void BtnAdminEditProduct_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new Window
            {
                Title = "Edit Product",
                Width = 380,
                Height = 350,
                WindowStartupLocation = WindowStartupLocation.CenterOwner,
                Owner = this
            };

            var panel = new StackPanel { Margin = new Thickness(10) };
            panel.Children.Add(new TextBlock { Text = "Product ID:" });
            var txtId = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtId);

            panel.Children.Add(new TextBlock { Text = "New Name (leave empty to keep):" });
            var txtName = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtName);

            panel.Children.Add(new TextBlock { Text = "New Price (leave empty to keep):" });
            var txtPrice = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtPrice);

            panel.Children.Add(new TextBlock { Text = "New Stock (leave empty to keep):" });
            var txtStock = new TextBox { Margin = new Thickness(0, 2, 0, 10) };
            panel.Children.Add(txtStock);

            var btnEdit = new Button { Content = "Update Product", Height = 35, Background = System.Windows.Media.Brushes.Orange, Foreground = System.Windows.Media.Brushes.White };
            panel.Children.Add(btnEdit);

            var lblMsg = new TextBlock { Margin = new Thickness(0, 10, 0, 0) };
            panel.Children.Add(lblMsg);

            dialog.Content = panel;

            btnEdit.Click += (s, args) =>
            {
                if (!int.TryParse(txtId.Text, out int id))
                {
                    lblMsg.Text = "Invalid Product ID!";
                    return;
                }

                try
                {
                    using (SqlConnection conn = new SqlConnection(connectionString))
                    {
                        conn.Open();
                        var updates = new System.Collections.Generic.List<string>();

                        if (!string.IsNullOrEmpty(txtName.Text))
                            updates.Add($"ProductName = '{txtName.Text.Replace("'", "''")}'");
                        if (decimal.TryParse(txtPrice.Text, out decimal price))
                            updates.Add($"Price = {price}");
                        if (int.TryParse(txtStock.Text, out int stock))
                            updates.Add($"Stock = {stock}");

                        if (updates.Count == 0)
                        {
                            lblMsg.Text = "No fields to update!";
                            return;
                        }

                        updates.Add($"UpdatedAt = '{DateTime.Now:yyyy-MM-dd}'");
                        SqlCommand cmd = new SqlCommand($"UPDATE PRODUCTS SET {string.Join(", ", updates)} WHERE ProductID = {id}", conn);
                        int rows = cmd.ExecuteNonQuery();

                        if (rows > 0)
                        {
                            lblMsg.Text = "Product updated successfully!";
                            lblMsg.Foreground = System.Windows.Media.Brushes.Green;
                            BtnAdminViewProducts_Click(null, null);
                            System.Threading.Tasks.Task.Delay(1500).ContinueWith(_ =>
                            {
                                Dispatcher.Invoke(() => dialog.Close());
                            });
                        }
                        else
                        {
                            lblMsg.Text = "Product not found!";
                        }
                    }
                }
                catch (Exception ex)
                {
                    lblMsg.Text = $"Error: {ex.Message}";
                    lblMsg.Foreground = System.Windows.Media.Brushes.Red;
                }
            };
            dialog.ShowDialog();
        }

        private void BtnAdminDeleteProduct_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new Window
            {
                Title = "Delete Product",
                Width = 320,
                Height = 180,
                WindowStartupLocation = WindowStartupLocation.CenterOwner,
                Owner = this
            };

            var panel = new StackPanel { Margin = new Thickness(10) };
            panel.Children.Add(new TextBlock { Text = "Product ID:" });
            var txtId = new TextBox { Margin = new Thickness(0, 2, 0, 10) };
            panel.Children.Add(txtId);

            var btnDelete = new Button { Content = "Delete Product", Height = 35, Background = System.Windows.Media.Brushes.Red, Foreground = System.Windows.Media.Brushes.White };
            panel.Children.Add(btnDelete);

            var lblMsg = new TextBlock { Margin = new Thickness(0, 10, 0, 0) };
            panel.Children.Add(lblMsg);

            dialog.Content = panel;

            btnDelete.Click += (s, args) =>
            {
                if (!int.TryParse(txtId.Text, out int id))
                {
                    lblMsg.Text = "Invalid Product ID!";
                    return;
                }

                if (MessageBox.Show($"Are you sure you want to delete product {id}?", "Confirm Delete", MessageBoxButton.YesNo, MessageBoxImage.Warning) == MessageBoxResult.Yes)
                {
                    try
                    {
                        using (SqlConnection conn = new SqlConnection(connectionString))
                        {
                            conn.Open();
                            SqlCommand cmd = new SqlCommand($"DELETE FROM PRODUCTS WHERE ProductID = {id}", conn);
                            int rows = cmd.ExecuteNonQuery();

                            if (rows > 0)
                            {
                                lblMsg.Text = "Product deleted successfully!";
                                lblMsg.Foreground = System.Windows.Media.Brushes.Green;
                                BtnAdminViewProducts_Click(null, null);
                                System.Threading.Tasks.Task.Delay(1500).ContinueWith(_ =>
                                {
                                    Dispatcher.Invoke(() => dialog.Close());
                                });
                            }
                            else
                            {
                                lblMsg.Text = "Product not found!";
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        lblMsg.Text = $"Error: {ex.Message}";
                        lblMsg.Foreground = System.Windows.Media.Brushes.Red;
                    }
                }
            };
            dialog.ShowDialog();
        }

        private void BtnAdminViewCategories_Click(object sender, RoutedEventArgs e)
        {
            LoadData("SELECT CategoryID, CategoryName, Description FROM CATEGORY ORDER BY CategoryID", "All Categories");
        }

        private void BtnAdminViewOrders_Click(object sender, RoutedEventArgs e)
        {
            LoadData(@"SELECT o.OrderID, o.OrderDate, o.Status, c.FirstName + ' ' + c.LastName AS CustomerName,
                              ISNULL(p.Status, 'Not Paid') AS PaymentStatus, ISNULL(s.Status, 'Not Created') AS ShipmentStatus
                       FROM ORDERS o
                       INNER JOIN CUSTOMER c ON o.CustomerID = c.CustomerID
                       LEFT JOIN PAYMENT p ON o.OrderID = p.OrderID
                       LEFT JOIN SHIPMENT s ON o.OrderID = s.OrderID
                       ORDER BY o.OrderID DESC", "All Orders (Admin)");
        }

        private void BtnAdminUpdateOrder_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new Window
            {
                Title = "Update Order Status",
                Width = 320,
                Height = 220,
                WindowStartupLocation = WindowStartupLocation.CenterOwner,
                Owner = this
            };

            var panel = new StackPanel { Margin = new Thickness(10) };
            panel.Children.Add(new TextBlock { Text = "Order ID:" });
            var txtId = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtId);

            panel.Children.Add(new TextBlock { Text = "New Status:", Margin = new Thickness(0, 10, 0, 5) });
            var cmbStatus = new ComboBox { Margin = new Thickness(0, 2, 0, 10) };
            cmbStatus.Items.Add("Pending");
            cmbStatus.Items.Add("Confirmed");
            cmbStatus.Items.Add("Shipped");
            cmbStatus.Items.Add("Delivered");
            cmbStatus.Items.Add("Cancelled");
            cmbStatus.SelectedIndex = 0;
            panel.Children.Add(cmbStatus);

            var btnUpdate = new Button { Content = "Update Status", Height = 35, Background = System.Windows.Media.Brushes.Orange, Foreground = System.Windows.Media.Brushes.White };
            panel.Children.Add(btnUpdate);

            var lblMsg = new TextBlock { Margin = new Thickness(0, 10, 0, 0) };
            panel.Children.Add(lblMsg);

            dialog.Content = panel;

            btnUpdate.Click += (s, args) =>
            {
                if (!int.TryParse(txtId.Text, out int id))
                {
                    lblMsg.Text = "Invalid Order ID!";
                    return;
                }

                try
                {
                    using (SqlConnection conn = new SqlConnection(connectionString))
                    {
                        conn.Open();
                        SqlCommand cmd = new SqlCommand("usp_UpdateOrderStatus", conn);
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.Parameters.AddWithValue("@OrderID", id);
                        cmd.Parameters.AddWithValue("@NewStatus", cmbStatus.SelectedItem.ToString());
                        cmd.ExecuteNonQuery();

                        lblMsg.Text = $"Order {id} status updated to {cmbStatus.SelectedItem}!";
                        lblMsg.Foreground = System.Windows.Media.Brushes.Green;
                        BtnAdminViewOrders_Click(null, null);
                        System.Threading.Tasks.Task.Delay(1500).ContinueWith(_ =>
                        {
                            Dispatcher.Invoke(() => dialog.Close());
                        });
                    }
                }
                catch (Exception ex)
                {
                    lblMsg.Text = $"Error: {ex.Message}";
                    lblMsg.Foreground = System.Windows.Media.Brushes.Red;
                }
            };
            dialog.ShowDialog();
        }

        private void BtnAdminViewCustomers_Click(object sender, RoutedEventArgs e)
        {
            LoadData("SELECT CustomerID, FirstName, LastName, Email, City, Country, RegistrationDate, IsActive FROM CUSTOMER ORDER BY CustomerID", "All Customers (Admin)");
        }

        private void BtnAdminToggleCustomer_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new Window
            {
                Title = "Manage Customer Status",
                Width = 320,
                Height = 220,
                WindowStartupLocation = WindowStartupLocation.CenterOwner,
                Owner = this
            };

            var panel = new StackPanel { Margin = new Thickness(10) };
            panel.Children.Add(new TextBlock { Text = "Customer ID:" });
            var txtId = new TextBox { Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtId);

            panel.Children.Add(new TextBlock { Text = "Action:", Margin = new Thickness(0, 10, 0, 5) });
            var cmbAction = new ComboBox { Margin = new Thickness(0, 2, 0, 10) };
            cmbAction.Items.Add("Activate");
            cmbAction.Items.Add("Deactivate");
            cmbAction.SelectedIndex = 0;
            panel.Children.Add(cmbAction);

            var btnApply = new Button { Content = "Apply", Height = 35 };
            panel.Children.Add(btnApply);

            var lblMsg = new TextBlock { Margin = new Thickness(0, 10, 0, 0) };
            panel.Children.Add(lblMsg);

            dialog.Content = panel;

            btnApply.Click += (s, args) =>
            {
                if (!int.TryParse(txtId.Text, out int id))
                {
                    lblMsg.Text = "Invalid Customer ID!";
                    return;
                }

                bool isActive = cmbAction.SelectedIndex == 0;
                string status = isActive ? "true" : "false";
                string action = isActive ? "activated" : "deactivated";

                try
                {
                    using (SqlConnection conn = new SqlConnection(connectionString))
                    {
                        conn.Open();
                        SqlCommand cmd = new SqlCommand($"UPDATE CUSTOMER SET IsActive = '{status}' WHERE CustomerID = {id}", conn);
                        int rows = cmd.ExecuteNonQuery();

                        if (rows > 0)
                        {
                            lblMsg.Text = $"Customer {id} has been {action}!";
                            lblMsg.Foreground = System.Windows.Media.Brushes.Green;
                            BtnAdminViewCustomers_Click(null, null);
                        }
                        else
                        {
                            lblMsg.Text = "Customer not found!";
                        }
                    }
                }
                catch (Exception ex)
                {
                    lblMsg.Text = $"Error: {ex.Message}";
                    lblMsg.Foreground = System.Windows.Media.Brushes.Red;
                }
            };
            dialog.ShowDialog();
        }

        private void BtnAdminSalesReport_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new Window
            {
                Title = "Sales Report",
                Width = 380,
                Height = 220,
                WindowStartupLocation = WindowStartupLocation.CenterOwner,
                Owner = this
            };

            var panel = new StackPanel { Margin = new Thickness(10) };
            panel.Children.Add(new TextBlock { Text = "Start Date (YYYY-MM-DD):" });
            var txtStart = new TextBox { Text = "2024-01-01", Margin = new Thickness(0, 2, 0, 5) };
            panel.Children.Add(txtStart);

            panel.Children.Add(new TextBlock { Text = "End Date (YYYY-MM-DD):" });
            var txtEnd = new TextBox { Text = DateTime.Now.ToString("yyyy-MM-dd"), Margin = new Thickness(0, 2, 0, 10) };
            panel.Children.Add(txtEnd);

            var btnReport = new Button { Content = "Generate Report", Height = 35 };
            panel.Children.Add(btnReport);

            var lblMsg = new TextBlock { Margin = new Thickness(0, 10, 0, 0) };
            panel.Children.Add(lblMsg);

            dialog.Content = panel;

            btnReport.Click += (s, args) =>
            {
                try
                {
                    using (SqlConnection conn = new SqlConnection(connectionString))
                    {
                        conn.Open();
                        SqlCommand cmd = new SqlCommand("usp_SalesReport", conn);
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.Parameters.AddWithValue("@StartDate", txtStart.Text);
                        cmd.Parameters.AddWithValue("@EndDate", txtEnd.Text);

                        SqlDataAdapter adapter = new SqlDataAdapter(cmd);
                        DataTable dt = new DataTable();
                        adapter.Fill(dt);

                        dataGrid.ItemsSource = dt.DefaultView;
                        lblPanelTitle.Text = $"Sales Report: {txtStart.Text} to {txtEnd.Text}";
                        dialog.Close();
                    }
                }
                catch (Exception ex)
                {
                    lblMsg.Text = $"Error: {ex.Message}";
                    lblMsg.Foreground = System.Windows.Media.Brushes.Red;
                }
            };
            dialog.ShowDialog();
        }
    }
}