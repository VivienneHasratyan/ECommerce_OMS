# E-Commerce Order Management System – WPF Application

**Authors:** Zhozefina GASPARYAN, Vivien HASRATYAN, Tigran ELOYAN  
**Course:** Database Modeling and Implementation   
**Date:** April 2026

---

## About This Project

This is the desktop application component of our database project. It provides a graphical user interface for the E-Commerce Order Management System database.

The application is written in C# using Windows Presentation Foundation (WPF) and connects directly to a Microsoft SQL Server database. It demonstrates how a real-world application would interact with our database design.

---

## What the Application Does

The application has two main user roles: **Customer** and **Admin**. Each role has its own set of functions.

### Customer Functions (10)

| # | Function | What It Does |
|---|----------|---------------|
| 1 | Browse Products | View all products with prices and stock levels |
| 2 | Search by Category | Filter products by category ID |
| 3 | Add to Cart | Add products to shopping cart with quantity |
| 4 | View Cart | See cart contents with subtotals |
| 5 | Place Order | Enter shipping address, choose payment, confirm order |
| 6 | My Orders | View order history with status and totals |
| 7 | Make Payment | Pay for orders that are still pending |
| 8 | Track Shipment | Check delivery status using order ID |
| 9 | Write Review | Rate products (1-5 stars) and leave comments |
| 10 | My Profile | View and update personal information |

### Admin Functions (10)

| # | Function | What It Does |
|---|----------|---------------|
| 1 | View All Products | Complete product list with category and supplier |
| 2 | Add Product | Insert new products into the database |
| 3 | Edit Product | Update product prices or stock quantities |
| 4 | Delete Product | Remove products from the catalog |
| 5 | View Categories | Display all category IDs and names |
| 6 | View All Orders | See every customer order with status |
| 7 | Update Order Status | Change order status (Pending/Confirmed/Shipped/Delivered/Cancelled) |
| 8 | View All Customers | Complete customer directory |
| 9 | Manage Customer Status | Activate or deactivate customer accounts |
| 10 | Sales Report | Generate revenue report by date range |

---

## Technology Stack

| Component | Technology |
|-----------|------------|
| Framework | .NET Framework 4.7.2 |
| UI Platform | WPF (Windows Presentation Foundation) |
| Language | C# |
| Database Connectivity | System.Data.SqlClient |
| Database | Microsoft SQL Server |

---

## How to Run the Application

### Prerequisites

- Windows operating system
- Visual Studio 2019 or 2022 (with .NET desktop development workload)
- SQL Server instance with the ECommerceOMS database
- .NET Framework 4.7.2 or higher

### Steps

1. **Clone or download the repository**

2. **Open the solution**  
   Double-click `ECommerceWPF.sln` to open in Visual Studio

3. **Update the connection string**  
   In `MainWindow.xaml.cs`, find this line:
   ```csharp
   private string connectionString = @"Server=YOUR_SERVER_NAME;Database=ECommerceOMS;Trusted_Connection=True;";
