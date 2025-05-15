#nullable enable
using Microsoft.Data.SqlClient;
using System; // Для DateTime, DBNull, Convert
using System.Collections.Generic; // Для List, Dictionary
using System.Data;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.IO; // Для Path, File
using FastReport; // FastReport
using FastReport.Data; // FastReport Data
using FastReport.Export.PdfSimple; // FastReport PDF export
using System.Diagnostics; // Для Process.Start
using FastReport.Utils;
using System.Windows.Data;

namespace SalesManagementSystem
{
    public partial class MainWindow : Window, INotifyPropertyChanged
    {
        // --- Поля та властивості ---
        private SqlConnection connection = new SqlConnection();
        private string currentUsername = string.Empty;
        private string server = string.Empty;
        private string database = string.Empty;

        public static List<ProductInfo> AvailableProductsForOrder { get; private set; } = new List<ProductInfo>();
        private ObservableCollection<SupplierOrderDetailItem> _currentSupplierOrderDetails = new ObservableCollection<SupplierOrderDetailItem>();
        public ObservableCollection<SupplierOrderDetailItem> CurrentSupplierOrderDetails
        {
            get => _currentSupplierOrderDetails;
            set
            {
                _currentSupplierOrderDetails = value ?? new ObservableCollection<SupplierOrderDetailItem>();
                OnPropertyChanged(nameof(CurrentSupplierOrderDetails));
            }
        }
        private ObservableCollection<SaleDetailGridItem> currentSaleDetails = new ObservableCollection<SaleDetailGridItem>();
        private List<SaleDetailGridItem> availableProductsForSaleDetails = new List<SaleDetailGridItem>();

        private string? _selectedSupplierId = string.Empty;
        public string? SelectedSupplierId
        {
            get => _selectedSupplierId;
            set
            {
                _selectedSupplierId = value;
                OnPropertyChanged(nameof(SelectedSupplierId));
            }
        }

        private bool canUpdateTable = false;
        private bool canDeleteTable = false;

        // Додано змінну для шляху до шаблонів звітів
        private string reportsDirectory = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Reports");

        // --- Конструктор та ініціалізація ---
        public MainWindow()
        {
            InitializeComponent();
            DataContext = this;
            ShowLoginPanel();
            CreateSaleDetailsDataGrid.ItemsSource = currentSaleDetails;
            SaleDetailGridItem.SetAvailableProducts(availableProductsForSaleDetails);

            // Створюємо директорію для звітів, якщо її немає
            if (!Directory.Exists(reportsDirectory))
            {
                Directory.CreateDirectory(reportsDirectory);
            }
        }

        // --- Авторизація та сесія ---
        private void ShowLoginPanel()
        {
            LoginPanel.Visibility = Visibility.Visible;
            MainApplicationArea.Visibility = Visibility.Collapsed;
            ConnectionStatusText.Text = "Статус підключення: Очікування авторизації";
            UsernameTextBox.Focus();
            if (RememberMeCheckBox.IsChecked == false)
            {
                UsernameTextBox.Text = "";
                PasswordTextBox.Password = "";
                LoginErrorMessage.Text = "";
            }
        }

        private void Login_Click(object sender, RoutedEventArgs e)
        {
            string username = UsernameTextBox.Text.Trim();
            string password = PasswordTextBox.Password;

            if (string.IsNullOrEmpty(username) || string.IsNullOrEmpty(password))
            {
                LoginErrorMessage.Text = "Будь ласка, введіть логін та пароль.";
                return;
            }
            AttemptLogin(username, password);
        }

        private void AttemptLogin(string username, string password)
        {
            // Зчитування параметрів з файлу
            if (string.IsNullOrEmpty(server) || string.IsNullOrEmpty(database))
            {
                try
                {
                    string filePath = "DBConnectionString";
                    string[] lines = File.ReadAllLines(filePath);

                    foreach (var line in lines)
                    {
                        if (!line.StartsWith(";") && !line.StartsWith("[") && line.Trim() != "")
                        {
                            string[] parts = line.Trim().Split(';');

                            foreach (string part in parts)
                            {
                                var kv = part.Split('=');
                                if (kv.Length != 2) continue;

                                string key = kv[0].Trim().ToLower();
                                string value = kv[1].Trim();

                                if (key == "data source")
                                    server = value;
                                else if (key == "initial catalog")
                                    database = value;
                            }
                            break;
                        }
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Помилка зчитування файлу підключення: " + ex.Message);
                    return;
                }
            }

            // Закриття попереднього підключення
            if (connection != null && connection.State == ConnectionState.Open)
            {
                try { connection.Close(); } catch { }
            }

            // Формування рядка підключення
            string connectionString = $"Server={server};Database={database};User ID={username};Password={password};TrustServerCertificate=True;Connect Timeout=15;MultipleActiveResultSets=True;";

            try
            {
                connection = new SqlConnection(connectionString);
                connection.Open();
                currentUsername = username;
                LoginErrorMessage.Text = "";
                ConnectionStatusText.Text = "Статус підключення: Успішно";
                ShowMainApplicationArea();
            }
            catch (SqlException sqlEx)
            {
                LoginErrorMessage.Text = $"Помилка підключення до БД: {sqlEx.Number} - {sqlEx.Message}";
                ConnectionStatusText.Text = "Статус підключення: Помилка";
            }
            catch (Exception ex)
            {
                LoginErrorMessage.Text = "Виникла помилка: " + ex.Message;
                ConnectionStatusText.Text = "Статус підключення: Помилка";
                Console.WriteLine(ex.ToString());
            }
        }

        private void LogOut_Click(object? sender, RoutedEventArgs? e)
        {
            if (connection != null && connection.State == ConnectionState.Open)
            {
                try { connection.Close(); } catch (Exception ex) { MessageBox.Show($"Помилка при закритті з'єднання: {ex.Message}"); }
            }
            currentUsername = string.Empty;
            ShowLoginPanel();
        }

        private void Exit_Click(object? sender, RoutedEventArgs? e)
        {
            if (connection != null && connection.State == ConnectionState.Open)
            {
                try { connection.Close(); } catch { }
            }
            Application.Current.Shutdown();
        }

        // --- Перевірка прав доступу ---
        private (bool canRead, bool canInsert, bool canUpdate, bool canDelete) CheckPermissions()
        {
            string query = @"
                SELECT 
                    ISNULL(HAS_PERMS_BY_NAME(NULL, 'DATABASE', 'SELECT'),0) AS CanRead,
                    ISNULL(HAS_PERMS_BY_NAME(NULL, 'DATABASE', 'INSERT'),0) AS CanInsert,
                    ISNULL(HAS_PERMS_BY_NAME(NULL, 'DATABASE', 'UPDATE'),0) AS CanUpdate,
                    ISNULL(HAS_PERMS_BY_NAME(NULL, 'DATABASE', 'DELETE'),0) AS CanDelete;
            ";
            using (SqlCommand cmd = new SqlCommand(query, connection))
            {
                try
                {
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            bool canRead = reader.GetInt32(0) == 1;
                            bool canInsert = reader.GetInt32(1) == 1;
                            bool canUpdate = reader.GetInt32(2) == 1;
                            bool canDelete = reader.GetInt32(3) == 1;
                            return (canRead, canInsert, canUpdate, canDelete);
                        }
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Помилка при перевірці прав: {ex.Message}");
                }
            }
            return (false, false, false, false);
        }

        // --- Навігація по UI ---
        private void ShowMainApplicationArea()
        {
            LoginPanel.Visibility = Visibility.Collapsed;
            MainApplicationArea.Visibility = Visibility.Visible;
            TablesViewGrid.Visibility = Visibility.Collapsed;
            ControlViewGrid.Visibility = Visibility.Collapsed;
            ConnectionStatusText.Text = $"Статус підключення: Підключено як {currentUsername}";
            var (canRead, canInsert, canUpdate, canDelete) = CheckPermissions();
            OpenTables.Visibility = canRead ? Visibility.Visible : Visibility.Collapsed;
            OpenControl.Visibility = (canInsert || canUpdate || canDelete) ? Visibility.Visible : Visibility.Collapsed;
            MenuWarningMessage.Visibility = (!canRead && !(canInsert || canUpdate || canDelete)) ? Visibility.Visible : Visibility.Collapsed;
            canUpdateTable = canUpdate;
            canDeleteTable = canDelete;
        }

        private void OpenTables_Click(object? sender, RoutedEventArgs? e)
        {
            MainApplicationArea.Visibility = Visibility.Collapsed;
            TablesViewGrid.Visibility = Visibility.Visible;
            PopulateTableSelector();
            TableSelectorComboBox_SelectionChanged(null, null); // Додаємо цей рядок для оновлення гріду
        }

        private void OpenControl_Click(object? sender, RoutedEventArgs? e)
        {
            MainApplicationArea.Visibility = Visibility.Collapsed;
            ControlViewGrid.Visibility = Visibility.Visible;
            LoadDataForControlComboBoxes();
        }

        private void BackToMenu_Click(object? sender, RoutedEventArgs? e)
        {
            TablesViewGrid.Visibility = Visibility.Collapsed;
            ControlViewGrid.Visibility = Visibility.Collapsed;
            MainApplicationArea.Visibility = Visibility.Visible;
            AddCustomerStatusTextBlock.Text = "";
            AddProductStatusTextBlock.Text = "";
            CreateSaleStatusTextBlock.Text = "";
        }

        // --- Робота з таблицями (перегляд) ---
        private void PopulateTableSelector()
        {
            if (connection.State != ConnectionState.Open)
            {
                MessageBox.Show("Немає активного підключення до бази даних.");
                return;
            }
            var tableDisplayMap = new Dictionary<string, string>
            {
                { "Category", "Категорії" },
                { "Customer", "Клієнти" },
                { "Employee", "Працівники" },
                { "Product", "Товари" },
                { "Sale", "Продажі" },
                { "Supplier", "Постачальники" },
                { "SupplierOrder", "Замовлення постачальнику" },
                { "View_AvailableProducts", "(Звіт) Доступні товари" },
                { "View_SaleDetails", "(Звіт) Деталі продажів" },
                { "View_SalesByCustomer", "(Звіт) Продажі за клієнтами" },
                { "View_SalesByEmployee", "(Звіт) Продажі за працівниками" },
                { "View_SupplierOrderDetails", "(Звіт) Деталі замовлень постач." }
            };
            var sortedList = tableDisplayMap
                .OrderBy(kvp => kvp.Value.StartsWith("(Звіт)") ? 1 : 0)
                .ThenBy(kvp => kvp.Value)
                .ToList();
            TableSelectorComboBox.ItemsSource = sortedList;
            TableSelectorComboBox.DisplayMemberPath = "Value";
            TableSelectorComboBox.SelectedValuePath = "Key";
            if (TableSelectorComboBox.Items.Count > 0)
                TableSelectorComboBox.SelectedIndex = 0;
        }

        private void TableSelectorComboBox_SelectionChanged(object? sender, SelectionChangedEventArgs? e)
        {
            string? selectedTable = TableSelectorComboBox.SelectedValue?.ToString();
            if (selectedTable == null || connection.State != ConnectionState.Open)
            {
                DataDisplayGrid.ItemsSource = null;
                TableEditButtonsPanel.Visibility = Visibility.Collapsed;
                return;
            }
            if (!IsValidSqlIdentifier(selectedTable))
            {
                MessageBox.Show("Неприпустима назва таблиці/представлення.");
                DataDisplayGrid.ItemsSource = null;
                TableEditButtonsPanel.Visibility = Visibility.Collapsed;
                return;
            }
            string query = $"SELECT * FROM [{selectedTable}]";
            try
            {
                SqlDataAdapter adapter = new SqlDataAdapter(query, connection);
                DataTable dataTable = new DataTable();
                adapter.Fill(dataTable);
                DataDisplayGrid.ItemsSource = dataTable.DefaultView;

                // Кнопки редагування та видалення: редагування приховано для "Sale" і "SupplierOrder"
                if (!selectedTable.StartsWith("View_") && (canUpdateTable || canDeleteTable))
                {
                    TableEditButtonsPanel.Visibility = Visibility.Visible;
                    // Приховати кнопку "Редагувати" для таблиць, де редагування не реалізовано
                    var editButton = TableEditButtonsPanel.Children
                        .OfType<Button>()
                        .FirstOrDefault(b => b.Content?.ToString() == "Редагувати");
                    if (editButton != null)
                        editButton.Visibility = (selectedTable == "Sale" || selectedTable == "SupplierOrder")
                            ? Visibility.Collapsed
                            : Visibility.Visible;
                }
                else
                {
                    TableEditButtonsPanel.Visibility = Visibility.Collapsed;
                }
            }
            catch (SqlException sqlEx)
            {
                MessageBox.Show($"Помилка завантаження даних для '{selectedTable}': {sqlEx.Message}");
                DataDisplayGrid.ItemsSource = null;
                TableEditButtonsPanel.Visibility = Visibility.Collapsed;
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Загальна помилка: {ex.Message}");
                DataDisplayGrid.ItemsSource = null;
                TableEditButtonsPanel.Visibility = Visibility.Collapsed;
            }
        }

        private bool IsValidSqlIdentifier(string? identifier)
        {
            if (string.IsNullOrWhiteSpace(identifier)) return false;
            return identifier.All(c => char.IsLetterOrDigit(c) || c == '_');
        }

        private void EditTableRow_Click(object sender, RoutedEventArgs e)
        {
            if (DataDisplayGrid.SelectedItem is DataRowView row)
            {
                string? selectedTable = TableSelectorComboBox.SelectedValue?.ToString();
                if (string.IsNullOrEmpty(selectedTable)) return;

                try
                {
                    switch (selectedTable)
                    {
                        case "Product":
                            {
                                string productId = row["ProductID"]?.ToString() ?? "";
                                string categoryId = row["CategoryID"]?.ToString() ?? "";
                                string productName = row["ProductName"]?.ToString() ?? "";
                                decimal price = row["Price"] != DBNull.Value ? Convert.ToDecimal(row["Price"]) : 0;

                                // Відкриваємо форму редагування (див. нижче)
                                var editWindow = new ProductEditDialog(productName, price);
                                editWindow.Owner = this;
                                if (editWindow.ShowDialog() != true)
                                    return; // Користувач натиснув Cancel

                                string inputName = editWindow.ProductName;
                                decimal newPrice = editWindow.ProductPrice;

                                if (string.IsNullOrWhiteSpace(inputName) || newPrice <= 0)
                                {
                                    MessageBox.Show("Некоректні дані.");
                                    return;
                                }

                                using (var cmd = new SqlCommand("usp_UpdateProduct", connection))
                                {
                                    cmd.CommandType = CommandType.StoredProcedure;
                                    cmd.Parameters.AddWithValue("@ProductID", productId);
                                    cmd.Parameters.AddWithValue("@CategoryID", categoryId);
                                    cmd.Parameters.AddWithValue("@ProductName", inputName);
                                    cmd.Parameters.AddWithValue("@Price", newPrice);
                                    cmd.ExecuteNonQuery();
                                }
                                break;
                            }
                        case "Category":
                            {
                                string categoryId = row["CategoryID"].ToString() ?? "";
                                string categoryName = row["CategoryName"].ToString() ?? "";
                                var editWindow = new CategoryEditDialog(categoryName) { Owner = this };
                                if (editWindow.ShowDialog() != true)
                                    return;

                                string inputName = editWindow.CategoryName;
                                if (string.IsNullOrWhiteSpace(inputName))
                                {
                                    MessageBox.Show("Некоректні дані.");
                                    return;
                                }
                                using (var cmd = new SqlCommand("usp_UpdateCategory", connection))
                                {
                                    cmd.CommandType = CommandType.StoredProcedure;
                                    cmd.Parameters.AddWithValue("@CategoryID", categoryId);
                                    cmd.Parameters.AddWithValue("@CategoryName", inputName);
                                    cmd.ExecuteNonQuery();
                                }
                                break;
                            }
                        case "Customer":
                            {
                                string customerId = row["CustomerID"].ToString() ?? "";
                                string fullName = row["FullName"].ToString() ?? "";
                                string phone = row["Phone"].ToString() ?? "";
                                string email = row["Email"].ToString() ?? "";

                                var editWindow = new CustomerEditDialog(fullName, phone, email) { Owner = this };
                                if (editWindow.ShowDialog() != true)
                                    return;

                                string inputName = editWindow.CustomerName;
                                string inputPhone = editWindow.CustomerPhone;
                                string inputEmail = editWindow.CustomerEmail;

                                if (string.IsNullOrWhiteSpace(inputName))
                                {
                                    MessageBox.Show("ПІБ не може бути порожнім.");
                                    return;
                                }

                                using (var cmd = new SqlCommand("usp_UpdateCustomer", connection))
                                {
                                    cmd.CommandType = CommandType.StoredProcedure;
                                    cmd.Parameters.AddWithValue("@CustomerID", customerId);
                                    cmd.Parameters.AddWithValue("@FullName", inputName);
                                    cmd.Parameters.AddWithValue("@Phone", string.IsNullOrWhiteSpace(inputPhone) ? (object)DBNull.Value : inputPhone);
                                    cmd.Parameters.AddWithValue("@Email", string.IsNullOrWhiteSpace(inputEmail) ? (object)DBNull.Value : inputEmail);
                                    cmd.ExecuteNonQuery();
                                }
                                break;
                            }
                        default:
                            MessageBox.Show("Редагування для цієї таблиці не реалізовано.");
                            return;
                    }

                    MessageBox.Show("Запис оновлено.");
                    TableSelectorComboBox_SelectionChanged(null, null); // Оновити грід
                }
                catch (SqlException ex)
                {
                    MessageBox.Show($"Помилка SQL: {ex.Message}");
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Помилка: {ex.Message}");
                }
            }
        }

        private void DeleteTableRow_Click(object sender, RoutedEventArgs e)
        {
            if (DataDisplayGrid.SelectedItem is DataRowView row)
            {
                var result = MessageBox.Show("Ви дійсно бажаєте видалити цей запис?", "Підтвердження видалення", MessageBoxButton.YesNo, MessageBoxImage.Warning);
                if (result != MessageBoxResult.Yes) return;

                string? selectedTable = TableSelectorComboBox.SelectedValue?.ToString();
                if (string.IsNullOrEmpty(selectedTable)) return;

                try
                {
                    using (var cmd = new SqlCommand())
                    {
                        cmd.Connection = connection;
                        cmd.CommandType = CommandType.StoredProcedure;

                        switch (selectedTable)
                        {
                            case "Sale":
                                cmd.CommandText = "usp_DeleteSale";
                                cmd.Parameters.AddWithValue("@SaleID", row["SaleID"]);
                                break;
                            case "Product":
                                cmd.CommandText = "usp_DeleteProduct";
                                cmd.Parameters.AddWithValue("@ProductID", row["ProductID"]);
                                break;
                            case "Category":
                                cmd.CommandText = "usp_DeleteCategory";
                                cmd.Parameters.AddWithValue("@CategoryID", row["CategoryID"]);
                                break;
                            case "Customer":
                                cmd.CommandText = "usp_DeleteCustomer";
                                cmd.Parameters.AddWithValue("@CustomerID", row["CustomerID"]);
                                break;
                            case "Employee":
                                cmd.CommandText = "usp_DeleteEmployee";
                                cmd.Parameters.AddWithValue("@EmployeeID", row["EmployeeID"]);
                                break;
                            case "Supplier":
                                cmd.CommandText = "usp_DeleteSupplier";
                                cmd.Parameters.AddWithValue("@SupplierID", row["SupplierID"]);
                                break;
                            default:
                                MessageBox.Show("Видалення для цієї таблиці не реалізовано.");
                                return;
                        }

                        cmd.ExecuteNonQuery();
                        MessageBox.Show("Запис успішно видалено.");
                        TableSelectorComboBox_SelectionChanged(null, null); // Оновити грід
                    }
                }
                catch (SqlException ex)
                {
                    MessageBox.Show($"Помилка SQL: {ex.Message}");
                }
                catch (Exception ex) {
                    MessageBox.Show($"Помилка: {ex.Message}");
                }
            }
        }

        private void GenerateReportButton_Click(object sender, RoutedEventArgs e)
        {
            if (TableSelectorComboBox.SelectedValue == null)
            {
                MessageBox.Show("Будь ласка, оберіть таблицю або представлення для генерації звіту.", "Інформація", MessageBoxButton.OK, MessageBoxImage.Information);
                return;
            }

            string selectedTableOrView = TableSelectorComboBox.SelectedValue.ToString() ?? "UnknownTable";
            string reportTitle = TableSelectorComboBox.SelectedItem is KeyValuePair<string, string> kvp
                ? kvp.Value
                : selectedTableOrView;

            try
            {
                Report report = new Report();

                string query = $"SELECT * FROM [{selectedTableOrView}]";
                DataTable dataForReport = new DataTable(selectedTableOrView);

                if (connection == null || connection.State != ConnectionState.Open)
                {
                    MessageBox.Show("З'єднання з базою даних не встановлено.", "Помилка", MessageBoxButton.OK, MessageBoxImage.Error);
                    return;
                }

                using (SqlDataAdapter adapter = new SqlDataAdapter(query, connection))
                {
                    adapter.Fill(dataForReport);
                }

                if (dataForReport.Rows.Count == 0)
                {
                    MessageBox.Show("Немає даних для відображення у звіті.", "Інформація", MessageBoxButton.OK, MessageBoxImage.Information);
                    return;
                }

                DataSet ds = new DataSet();
                ds.Tables.Add(dataForReport);
                report.RegisterData(ds, selectedTableOrView, true);

                ReportPage page = new ReportPage();
                page.Name = "ReportPage1";
                report.Pages.Add(page);
                if (dataForReport.Columns.Count > 6)
                    page.Landscape = true;

                ReportTitleBand reportTitleBand = new ReportTitleBand();
                reportTitleBand.Name = "ReportTitle1";
                reportTitleBand.Height = Units.Centimeters * 1.5f;
                page.ReportTitle = reportTitleBand;

                TextObject reportTitleText = new TextObject();
                reportTitleText.Name = "TextTitle";
                reportTitleText.Bounds = new System.Drawing.RectangleF(0, 0, page.PaperWidth * Units.Millimeters - (page.LeftMargin + page.RightMargin) * Units.Millimeters, Units.Centimeters * 1.0f);
                reportTitleText.Text = $"Звіт по: {reportTitle}";
                reportTitleText.Font = new System.Drawing.Font("Arial", 16, System.Drawing.FontStyle.Bold);
                reportTitleText.HorzAlign = HorzAlign.Center;
                reportTitleText.VertAlign = VertAlign.Center;
                reportTitleBand.Objects.Add(reportTitleText);

                PageHeaderBand pageHeaderBand = new PageHeaderBand();
                pageHeaderBand.Name = "PageHeader1";
                pageHeaderBand.Height = 15f;
                page.PageHeader = pageHeaderBand;

                DataBand dataBand = new DataBand();
                dataBand.Name = "Data1";
                dataBand.Height = 15f;
                dataBand.DataSource = report.GetDataSource(selectedTableOrView);
                page.Bands.Add(dataBand);

                PageFooterBand pageFooterBand = new PageFooterBand();
                pageFooterBand.Name = "PageFooter1";
                pageFooterBand.Height = Units.Centimeters * 0.7f;
                page.PageFooter = pageFooterBand;

                TextObject pageNumberText = new TextObject();
                pageNumberText.Name = "TextPageNumber";
                pageNumberText.Text = "Сторінка [Page#] з [TotalPages#]";
                pageNumberText.Font = new System.Drawing.Font("Arial", 9);
                pageNumberText.HorzAlign = HorzAlign.Right;
                pageFooterBand.Objects.Add(pageNumberText);

                float pageWidthMm = (float)((page.PaperWidth - page.LeftMargin - page.RightMargin) * Units.Millimeters);
                float minColumnWidth = 40f; // Мінімальна ширина колонки (мм)
                float columnWidth = Math.Max(pageWidthMm / dataForReport.Columns.Count, minColumnWidth);

                float currentX = 0;
                foreach (DataColumn column in dataForReport.Columns)
                {
                    // Заголовок
                    TextObject headerText = new TextObject();
                    headerText.Name = $"Header_{column.ColumnName}";
                    headerText.Bounds = new System.Drawing.RectangleF(currentX, 0, columnWidth, pageHeaderBand.Height);
                    headerText.Text = column.ColumnName;
                    headerText.Font = new System.Drawing.Font("Arial", 10, System.Drawing.FontStyle.Bold);
                    headerText.Border.Lines = BorderLines.All;
                    headerText.HorzAlign = HorzAlign.Center;
                    headerText.VertAlign = VertAlign.Center;
                    headerText.WordWrap = true;
                    pageHeaderBand.Objects.Add(headerText);

                    // Дані
                    TextObject dataText = new TextObject();
                    dataText.Name = $"Data_{column.ColumnName}";
                    dataText.Bounds = new System.Drawing.RectangleF(currentX, 0, columnWidth, dataBand.Height);

                    if (column.DataType == typeof(DateTime))
                    {
                        dataText.Text = $"[{selectedTableOrView}.{column.ColumnName}]";
                        dataText.HorzAlign = HorzAlign.Left;
                        dataText.Format = new FastReport.Format.DateFormat();
                    }
                    else if (column.DataType == typeof(decimal) || column.DataType == typeof(double) || column.DataType == typeof(float))
                    {
                        dataText.Text = $"[{selectedTableOrView}.{column.ColumnName}]";
                        dataText.HorzAlign = HorzAlign.Right;
                    }
                    else
                    {
                        dataText.Text = $"[{selectedTableOrView}.{column.ColumnName}]";
                        dataText.HorzAlign = HorzAlign.Left;
                        dataText.WordWrap = true;
                    }
                    dataText.Font = new System.Drawing.Font("Arial", 9);
                    dataText.Border.Lines = BorderLines.All;
                    dataText.VertAlign = VertAlign.Center;
                    dataBand.Objects.Add(dataText);

                    currentX += columnWidth;
                }

                string pdfFileName = Path.Combine(reportsDirectory, $"{selectedTableOrView}_Report_{DateTime.Now:yyyyMMddHHmmss}.pdf");
                PDFSimpleExport pdfExport = new PDFSimpleExport();
                report.Prepare();
                report.Export(pdfExport, pdfFileName);

                MessageBox.Show($"Звіт збережено у файл: {pdfFileName}", "Успіх", MessageBoxButton.OK, MessageBoxImage.Information);

                try
                {
                    ProcessStartInfo psi = new ProcessStartInfo(pdfFileName)
                    {
                        UseShellExecute = true
                    };
                    Process.Start(psi);
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Не вдалося автоматично відкрити PDF файл. Помилка: {ex.Message}", "Увага", MessageBoxButton.OK, MessageBoxImage.Warning);
                }
            }
            catch (SqlException sqlEx)
            {
                MessageBox.Show($"Помилка SQL при підготовці даних для звіту: {sqlEx.Message}", "Помилка SQL", MessageBoxButton.OK, MessageBoxImage.Error);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Помилка при генерації звіту: {ex.Message}\n{ex.StackTrace}", "Помилка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        // --- Завантаження даних у ComboBox/грид ---
        private void LoadComboBoxData(ComboBox comboBox, string query, string valueMember, string displayMember, string entityNameForErrorMessage)
        {
            if (connection == null || connection.State != ConnectionState.Open)
            {
                MessageBox.Show($"Неможливо завантажити список '{entityNameForErrorMessage}': з'єднання з БД не відкрито.", "Помилка", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            try
            {
                DataTable dataTable = new DataTable();
                using (SqlDataAdapter adapter = new SqlDataAdapter(query, connection))
                {
                    adapter.Fill(dataTable);
                }
                var items = dataTable.AsEnumerable()
                    .Select(row => new
                    {
                        SupplierID = row.Table.Columns.Contains("SupplierID") ? row["SupplierID"].ToString() : null,
                        OrganizationName = row.Table.Columns.Contains("OrganizationName") ? row["OrganizationName"].ToString() : null,
                        EmployeeID = row.Table.Columns.Contains("EmployeeID") ? row["EmployeeID"].ToString() : null,
                        FullName = row.Table.Columns.Contains("FullName") ? row["FullName"].ToString() : null,
                        CustomerID = row.Table.Columns.Contains("CustomerID") ? row["CustomerID"].ToString() : null,
                        CategoryID = row.Table.Columns.Contains("CategoryID") ? row["CategoryID"].ToString() : null,
                        CategoryName = row.Table.Columns.Contains("CategoryName") ? row["CategoryName"].ToString() : null
                    }).ToList();
                comboBox.ItemsSource = items;
                comboBox.DisplayMemberPath = displayMember;
                comboBox.SelectedValuePath = valueMember;
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Помилка завантаження списку '{entityNameForErrorMessage}': {ex.Message}", "Помилка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void LoadDataForControlComboBoxes()
        {
            if (connection == null || connection.State != ConnectionState.Open)
            {
                MessageBox.Show("З'єднання з БД не відкрито. Неможливо завантажити дані для комбо-боксів.", "Помилка", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }
            // Завантаження працівників і клієнтів для продажу
            LoadComboBoxData(CreateSaleEmployeeIDComboBox,
                "SELECT EmployeeID, FullName FROM Employee ORDER BY FullName",
                "EmployeeID", "FullName", "працівників");
            LoadComboBoxData(CreateSaleCustomerIDComboBox,
                "SELECT CustomerID, FullName FROM Customer ORDER BY FullName",
                "CustomerID", "FullName", "клієнтів");
            LoadComboBoxData(AddProductCategoryIDComboBox,
                "SELECT CategoryID, CategoryName FROM Category ORDER BY CategoryName",
                "CategoryID", "CategoryName", "категорій");
            LoadProductsForSaleDetailsGrid();
        }

        private void LoadProductsForSaleDetailsGrid()
        {
            availableProductsForSaleDetails.Clear();
            if (connection == null || connection.State != ConnectionState.Open)
            {
                MessageBox.Show("Неможливо завантажити список товарів: з'єднання з БД не відкрито.", "Помилка", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            string query = "SELECT ProductID, ProductName, Price FROM Product ORDER BY ProductName";
            try
            {
                using (SqlCommand cmd = new SqlCommand(query, connection))
                using (SqlDataReader reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        availableProductsForSaleDetails.Add(new SaleDetailGridItem
                        {
                            ProductID = reader["ProductID"].ToString() ?? string.Empty,
                            ProductName = reader["ProductName"].ToString() ?? string.Empty,
                            UnitPrice = Convert.ToDecimal(reader["Price"])
                        });
                    }
                }
                var productColumn = CreateSaleDetailsDataGrid.Columns
                                    .OfType<DataGridComboBoxColumn>()
                                    .FirstOrDefault(c => c.Header.ToString() == "Товар");
                if (productColumn != null)
                {
                    productColumn.ItemsSource = availableProductsForSaleDetails;
                }
                else
                {
                    MessageBox.Show("Технічна помилка: стовпець 'Товар' (DataGridComboBoxColumn) не знайдено.", "Помилка налаштування UI", MessageBoxButton.OK, MessageBoxImage.Error);
                }
                SaleDetailGridItem.SetAvailableProducts(availableProductsForSaleDetails);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Помилка завантаження списку товарів для деталей продажу: {ex.Message}\nПеревірте налаштування MARS.", "Помилка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        // --- Додавання/редагування сутностей ---
        private void AddCustomerButton_Click(object sender, RoutedEventArgs e)
        {
            if (connection.State != ConnectionState.Open)
            {
                MessageBox.Show("Немає з'єднання з БД.", "Помилка", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }
            string fullName = AddCustomerFullNameTextBox.Text.Trim();
            string phone = AddCustomerPhoneTextBox.Text.Trim();
            string email = AddCustomerEmailTextBox.Text.Trim();
            if (string.IsNullOrWhiteSpace(fullName))
            {
                MessageBox.Show("ПІБ є обов'язковим.", "Помилка", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            try
            {
                using (SqlCommand cmd = new SqlCommand("AddCustomer", connection))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@FullName", fullName);
                    cmd.Parameters.AddWithValue("@Phone", string.IsNullOrWhiteSpace(phone) ? (object)DBNull.Value : phone);
                    cmd.Parameters.AddWithValue("@Email", string.IsNullOrWhiteSpace(email) ? (object)DBNull.Value : email);
                    string? newCustomerId = cmd.ExecuteScalar()?.ToString();
                    if (!string.IsNullOrEmpty(newCustomerId))
                    {
                        MessageBox.Show($"Клієнта додано/знайдено. ID: {newCustomerId}", "Успіх", MessageBoxButton.OK, MessageBoxImage.Information);
                        AddCustomerFullNameTextBox.Text = "";
                        AddCustomerPhoneTextBox.Text = "";
                        AddCustomerEmailTextBox.Text = "";
                        LoadDataForControlComboBoxes();
                    }
                    else
                    {
                        MessageBox.Show("Не вдалося додати клієнта (процедура не повернула ID).", "Помилка", MessageBoxButton.OK, MessageBoxImage.Error);
                    }
                }
            }
            catch (SqlException sqlEx)
            {
                MessageBox.Show($"Помилка SQL: {sqlEx.Message}", "Помилка SQL", MessageBoxButton.OK, MessageBoxImage.Error);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Загальна помилка: {ex.Message}", "Помилка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void AddProductButton_Click(object sender, RoutedEventArgs e)
        {
            if (connection.State != ConnectionState.Open)
            {
                MessageBox.Show("Немає з'єднання з БД.", "Помилка", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }
            string? categoryId = AddProductCategoryIDComboBox.SelectedValue?.ToString();
            string productName = AddProductProductNameTextBox.Text.Trim();
            string priceStr = AddProductPriceTextBox.Text.Trim();
            string stockQuantityStr = AddProductStockQuantityTextBox.Text.Trim();
            if (string.IsNullOrEmpty(categoryId) || string.IsNullOrWhiteSpace(productName) || string.IsNullOrWhiteSpace(priceStr) || string.IsNullOrWhiteSpace(stockQuantityStr)
            )
            {
                MessageBox.Show("Всі поля (окрім кількості за замовчуванням) є обов'язковими.", "Помилка", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            if (!decimal.TryParse(priceStr, out decimal price) || price <= 0)
            {
                MessageBox.Show("Некоректна ціна.", "Помилка", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            if (!int.TryParse(stockQuantityStr, out int stockQuantity) || stockQuantity < 0)
            {
                MessageBox.Show("Некоректна кількість на складі.", "Помилка", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            try
            {
                using (SqlCommand cmd = new SqlCommand("AddProduct", connection))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@CategoryID", categoryId);
                    cmd.Parameters.AddWithValue("@ProductName", productName);
                    cmd.Parameters.AddWithValue("@Price", price);
                    cmd.Parameters.AddWithValue("@StockQuantity", stockQuantity);
                    string? newProductId = cmd.ExecuteScalar()?.ToString();
                    if (!string.IsNullOrEmpty(newProductId))
                    {
                        MessageBox.Show($"Товар додано/знайдено. ID: {newProductId}", "Успіх", MessageBoxButton.OK, MessageBoxImage.Information);
                        AddProductCategoryIDComboBox.SelectedIndex = -1;
                        AddProductProductNameTextBox.Text = "";
                        AddProductPriceTextBox.Text = "";
                        AddProductStockQuantityTextBox.Text = "0";
                        LoadProductsForSaleDetailsGrid();
                    }
                    else
                    {
                        MessageBox.Show("Не вдалося додати товар.", "Помилка", MessageBoxButton.OK, MessageBoxImage.Error);
                    }
                }
            }
            catch (SqlException sqlEx)
            {
                MessageBox.Show($"Помилка SQL: {sqlEx.Message}", "Помилка SQL", MessageBoxButton.OK, MessageBoxImage.Error);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Загальна помилка: {ex.Message}", "Помилка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void AddCategoryButton_Click(object sender, RoutedEventArgs e)
        {
            if (!ValidateConnection()) return;
            string categoryName = AddCategoryNameTextBox.Text.Trim();
            if (string.IsNullOrWhiteSpace(categoryName))
            {
                MessageBox.Show("Введіть назву категорії!", "Помилка", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            try
            {
                using (SqlCommand cmd = new SqlCommand("AddCategory", connection))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@CategoryName", categoryName);
                    string? newCategoryId = cmd.ExecuteScalar()?.ToString();
                    MessageBox.Show($"Категорія додана! ID: {newCategoryId}", "Успіх", MessageBoxButton.OK, MessageBoxImage.Information);
                    AddCategoryNameTextBox.Clear();
                    LoadDataForControlComboBoxes();
                }
            }
            catch (SqlException ex)
            {
                if (ex.Number == 2627)
                    MessageBox.Show("Категорія з такою назвою вже існує!", "Помилка", MessageBoxButton.OK, MessageBoxImage.Warning);
                else
                    MessageBox.Show($"Помилка: {ex.Message}", "Помилка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void AddSupplierButton_Click(object sender, RoutedEventArgs e)
        {
            if (!ValidateConnection()) return;
            string orgName = AddSupplierOrgNameTextBox.Text.Trim();
            if (string.IsNullOrWhiteSpace(orgName))
            {
                MessageBox.Show("Введіть назву організації!", "Помилка", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            try
            {
                using (SqlCommand cmd = new SqlCommand("AddSupplier", connection))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@OrganizationName", orgName);
                    cmd.Parameters.AddWithValue("@Phone", NullIfEmpty(AddSupplierPhoneTextBox.Text.Trim()));
                    cmd.Parameters.AddWithValue("@Email", NullIfEmpty(AddSupplierEmailTextBox.Text.Trim()));
                    string? newSupplierId = cmd.ExecuteScalar()?.ToString();
                    MessageBox.Show($"Постачальник доданий! ID: {newSupplierId}", "Успіх", MessageBoxButton.OK, MessageBoxImage.Information);
                    ClearSupplierFields();
                    LoadDataForControlComboBoxes();
                }
            }
            catch (SqlException ex)
            {
                if (ex.Number == 2627)
                    MessageBox.Show("Постачальник з такою назвою вже існує!", "Помилка", MessageBoxButton.OK, MessageBoxImage.Warning);
                else
                    MessageBox.Show($"Помилка: {ex.Message}", "Помилка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void AddEmployeeButton_Click(object sender, RoutedEventArgs e)
        {
            if (!ValidateConnection()) return;
            string fullName = AddEmployeeFullNameTextBox.Text.Trim();
            string position = AddEmployeePositionTextBox.Text.Trim();
            if (string.IsNullOrWhiteSpace(fullName) || string.IsNullOrWhiteSpace(position))
            {
                MessageBox.Show("Заповніть обов'язкові поля (ПІБ та Посада)!", "Помилка", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            try
            {
                using (SqlCommand cmd = new SqlCommand("AddEmployee", connection))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@FullName", fullName);
                    cmd.Parameters.AddWithValue("@Phone", NullIfEmpty(AddEmployeePhoneTextBox.Text.Trim()));
                    cmd.Parameters.AddWithValue("@Email", NullIfEmpty(AddEmployeeEmailTextBox.Text.Trim()));
                    cmd.Parameters.AddWithValue("@Position", position);
                    string? newEmployeeId = cmd.ExecuteScalar()?.ToString();
                    MessageBox.Show($"Працівник доданий! ID: {newEmployeeId}", "Успіх", MessageBoxButton.OK, MessageBoxImage.Information);
                    ClearEmployeeFields();
                    LoadDataForControlComboBoxes();
                }
            }
            catch (SqlException ex)
            {
                if (ex.Number == 2627)
                    MessageBox.Show("Працівник з таким ПІБ вже існує!", "Помилка", MessageBoxButton.OK, MessageBoxImage.Warning);
                else
                    MessageBox.Show($"Помилка: {ex.Message}", "Помилка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        // --- Створення продажу ---
        private void CreateSaleDetailsDataGrid_AddingNewItem(object sender, AddingNewItemEventArgs e)
        {
            e.NewItem = new SaleDetailGridItem();
        }

        private async void CreateSaleButton_Click(object sender, RoutedEventArgs e)
        {
            if (CreateSaleEmployeeIDComboBox.SelectedValue == null)
            {
                MessageBox.Show("Будь ласка, виберіть працівника.", "Помилка валідації", MessageBoxButton.OK, MessageBoxImage.Warning);
                CreateSaleStatusTextBlock.Text = "Помилка: Працівник не вибраний.";
                return;
            }
            if (CreateSaleCustomerIDComboBox.SelectedValue == null)
            {
                MessageBox.Show("Будь ласка, виберіть клієнта.", "Помилка валідації", MessageBoxButton.OK, MessageBoxImage.Warning);
                CreateSaleStatusTextBlock.Text = "Помилка: Клієнт не вибраний.";
                return;
            }
            string paymentMethod = CreateSalePaymentMethodTextBox.Text;
            if (string.IsNullOrWhiteSpace(paymentMethod))
            {
                MessageBox.Show("Будь ласка, вкажіть метод оплати.", "Помилка валідації", MessageBoxButton.OK, MessageBoxImage.Warning);
                CreateSaleStatusTextBlock.Text = "Помилка: Метод оплати не вказаний.";
                return;
            }
            DateTime? saleDate = CreateSaleSaleDatePicker.SelectedDate;
            if (!currentSaleDetails.Any())
            {
                MessageBox.Show("Будь ласка, додайте хоча б один товар до продажу.", "Помилка валідації", MessageBoxButton.OK, MessageBoxImage.Warning);
                CreateSaleStatusTextBlock.Text = "Помилка: Список товарів порожній.";
                return;
            }
            DataTable saleDetailsTable = new DataTable("UDTT_SaleDetailsType");
            saleDetailsTable.Columns.Add("ProductID", typeof(string));
            saleDetailsTable.Columns.Add("Quantity", typeof(int));
            saleDetailsTable.Columns.Add("UnitPrice", typeof(decimal));
            foreach (var item in currentSaleDetails)
            {
                if (string.IsNullOrEmpty(item.ProductID) || item.Quantity <= 0 || item.UnitPrice < 0)
                {
                    MessageBox.Show($"Некоректні дані для одного з товарів: Товар='{item.ProductName}', Кількість={item.Quantity}, Ціна={item.UnitPrice:C}. Будь ласка, перевірте всі рядки.", "Помилка валідації", MessageBoxButton.OK, MessageBoxImage.Warning);
                    CreateSaleStatusTextBlock.Text = "Помилка: Некоректні дані в деталях продажу.";
                    return;
                }
                saleDetailsTable.Rows.Add(item.ProductID, item.Quantity, item.UnitPrice);
            }
            if (connection == null || connection.State != ConnectionState.Open)
            {
                MessageBox.Show("Неможливо створити продаж: з'єднання з БД не відкрито.", "Помилка з'єднання", MessageBoxButton.OK, MessageBoxImage.Error);
                CreateSaleStatusTextBlock.Text = "Помилка: Немає з'єднання з БД.";
                return;
            }
            CreateSaleStatusTextBlock.Text = "Обробка запиту...";
            try
            {
                using (SqlCommand cmd = new SqlCommand("CreateSale", connection))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@EmployeeID", CreateSaleEmployeeIDComboBox.SelectedValue.ToString());
                    cmd.Parameters.AddWithValue("@CustomerID", CreateSaleCustomerIDComboBox.SelectedValue.ToString());
                    cmd.Parameters.AddWithValue("@SaleDate", saleDate.HasValue ? (object)saleDate.Value : DBNull.Value);
                    cmd.Parameters.AddWithValue("@PaymentMethod", paymentMethod);
                    SqlParameter detailsParam = cmd.Parameters.AddWithValue("@SaleDetails", saleDetailsTable);
                    detailsParam.SqlDbType = SqlDbType.Structured;
                    detailsParam.TypeName = "dbo.UDTT_SaleDetailsType";
                    using (SqlDataReader reader = await cmd.ExecuteReaderAsync())
                    {
                        if (await reader.ReadAsync())
                        {
                            string newSaleID = reader["NewSaleID"].ToString() ?? string.Empty;
                            decimal saleGrandTotal = Convert.ToDecimal(reader["SaleGrandTotal"]);
                            MessageBox.Show($"Продаж {newSaleID} успішно створено! Загальна сума: {saleGrandTotal:C}", "Успіх", MessageBoxButton.OK, MessageBoxImage.Information);
                            CreateSaleStatusTextBlock.Text = $"Продаж {newSaleID} успішно створено. Сума: {saleGrandTotal:C}.";
                            ClearCreateSaleForm();
                        }
                        else
                        {
                            CreateSaleStatusTextBlock.Text = "Продаж міг бути створений, але не вдалося отримати ID та суму.";
                        }
                    }
                }
            }
            catch (SqlException sqlEx)
            {
                MessageBox.Show($"Помилка SQL при створенні продажу: {sqlEx.Message}\nНомер помилки: {sqlEx.Number}\nПроцедура: {sqlEx.Procedure}", "Помилка SQL", MessageBoxButton.OK, MessageBoxImage.Error);
                CreateSaleStatusTextBlock.Text = $"Помилка SQL: {sqlEx.Message.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries).FirstOrDefault() ?? "Невідома SQL помилка"}";
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Загальна помилка при створенні продажу: {ex.Message}", "Помилка", MessageBoxButton.OK, MessageBoxImage.Error);
                CreateSaleStatusTextBlock.Text = $"Помилка: {ex.Message.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries).FirstOrDefault() ?? "Невідома помилка"}";
            }
        }

        private void ClearCreateSaleForm()
        {
            CreateSaleEmployeeIDComboBox.SelectedIndex = -1;
            CreateSaleCustomerIDComboBox.SelectedIndex = -1;
            CreateSaleSaleDatePicker.SelectedDate = null;
            CreateSalePaymentMethodTextBox.Clear();
            currentSaleDetails.Clear();
        }

        // --- Створення закупівлі ---
        private void LoadDataForSupplierOrderTab()
        {
            LoadComboBoxData(CreateOrderSupplierComboBox,
                "SELECT SupplierID, OrganizationName FROM Supplier ORDER BY OrganizationName",
                "SupplierID", "OrganizationName", "постачальників");
            AvailableProductsForOrder.Clear();
            try
            {
                using (SqlCommand cmd = new SqlCommand("SELECT ProductID, ProductName, Price FROM Product ORDER BY ProductName", connection))
                using (SqlDataReader reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        AvailableProductsForOrder.Add(new ProductInfo
                        {
                            ProductID = reader["ProductID"].ToString() ?? string.Empty,
                            ProductName = reader["ProductName"].ToString() ?? string.Empty,
                            Price = Convert.ToDecimal(reader["Price"])
                        });
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Помилка завантаження списку товарів: {ex.Message}", "Помилка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
            var productColumn = CreateOrderDetailsDataGrid.Columns
                .OfType<DataGridComboBoxColumn>()
                .FirstOrDefault(c => c.Header.ToString() == "Товар");
            if (productColumn != null)
            {
                productColumn.ItemsSource = AvailableProductsForOrder;
            }
        }

        private async void CreateSupplierOrderButton_Click(object sender, RoutedEventArgs e)
        {
            if (CreateOrderSupplierComboBox.SelectedValue == null)
            {
                MessageBox.Show("Будь ласка, оберіть постачальника!", "Помилка", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            if (!CurrentSupplierOrderDetails.Any() || CurrentSupplierOrderDetails.All(item => string.IsNullOrEmpty(item.ProductID) || item.Quantity <= 0))
            {
                MessageBox.Show("Будь ласка, додайте хоча б один товар із коректною кількістю!", "Помилка", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            if (CurrentSupplierOrderDetails.Any(item => string.IsNullOrEmpty(item.ProductID)))
            {
                MessageBox.Show("Один або декілька рядків не мають вибраного товару.", "Помилка", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            if (CurrentSupplierOrderDetails.Any(item => item.Quantity <= 0))
            {
                MessageBox.Show("Кількість для кожного товару повинна бути більше нуля.", "Помилка", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            try
            {
                DataTable orderDetailsTable = new DataTable("UDTT_OrderDetailsType");
                orderDetailsTable.Columns.Add("ProductID", typeof(string));
                orderDetailsTable.Columns.Add("OrderQuantity", typeof(int));
                orderDetailsTable.Columns.Add("UnitPrice", typeof(decimal));
                foreach (var item in CurrentSupplierOrderDetails)
                {
                    if (!string.IsNullOrEmpty(item.ProductID) && item.Quantity > 0)
                    {
                        orderDetailsTable.Rows.Add(item.ProductID, item.Quantity, item.UnitPrice);
                    }
                }
                if (orderDetailsTable.Rows.Count == 0)
                {
                    MessageBox.Show("Немає дійсних товарів для замовлення.", "Помилка", MessageBoxButton.OK, MessageBoxImage.Warning);
                    return;
                }
                using (SqlCommand cmd = new SqlCommand("CreateSupplierOrder", connection))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@SupplierID", CreateOrderSupplierComboBox.SelectedValue);
                    cmd.Parameters.AddWithValue("@OrderDate", CreateOrderDatePicker.SelectedDate.HasValue ? (object)CreateOrderDatePicker.SelectedDate.Value : DBNull.Value);
                    SqlParameter detailsParam = cmd.Parameters.AddWithValue("@OrderDetails", orderDetailsTable);
                    detailsParam.SqlDbType = SqlDbType.Structured;
                    detailsParam.TypeName = "dbo.UDTT_OrderDetailsType";
                    using (SqlDataReader reader = await cmd.ExecuteReaderAsync())
                    {
                        if (await reader.ReadAsync())
                        {
                            string? newOrderID = reader["NewOrderID"]?.ToString();
                            decimal orderGrandTotal = reader["OrderGrandTotal"] != DBNull.Value ? Convert.ToDecimal(reader["OrderGrandTotal"]) : 0;
                            MessageBox.Show($"Закупівля {newOrderID} успішно створена! Загальна сума: {orderGrandTotal:N2}", "Успіх", MessageBoxButton.OK, MessageBoxImage.Information);
                            CurrentSupplierOrderDetails.Clear();
                            CreateOrderSupplierComboBox.SelectedIndex = -1;
                            CreateOrderDatePicker.SelectedDate = DateTime.Now;
                        }
                        else
                        {
                            MessageBox.Show("Закупівля створена, але не вдалося отримати деталі.", "Увага", MessageBoxButton.OK, MessageBoxImage.Warning);
                        }
                    }
                }
            }
            catch (SqlException sqlEx)
            {
                MessageBox.Show($"Помилка SQL: {sqlEx.Message}", "Помилка SQL", MessageBoxButton.OK, MessageBoxImage.Error);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Загальна помилка: {ex.Message}", "Помилка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        // --- Допоміжні методи ---
        private void ClearSupplierFields()
        {
            AddSupplierOrgNameTextBox.Clear();
            AddSupplierPhoneTextBox.Clear();
            AddSupplierEmailTextBox.Clear();
        }

        private void ClearEmployeeFields()
        {
            AddEmployeeFullNameTextBox.Clear();
            AddEmployeePhoneTextBox.Clear();
            AddEmployeeEmailTextBox.Clear();
            AddEmployeePositionTextBox.Clear();
        }

        private void Phone_PreviewTextInput(object sender, TextCompositionEventArgs e)
        {
            e.Handled = !Regex.IsMatch(e.Text, @"^[+0-9\s()-]*$");
        }

        private void Email_LostFocus(object sender, RoutedEventArgs e)
        {
            var textBox = (TextBox)sender;
            if (!string.IsNullOrEmpty(textBox.Text) && !IsValidEmail(textBox.Text))
            {
                MessageBox.Show("Невірний формат електронної пошти!");
                textBox.Focus();
            }
        }

        private bool IsValidEmail(string email)
        {
            try
            {
                var addr = new System.Net.Mail.MailAddress(email);
                return addr.Address == email;
            }
            catch
            {
                return false;
            }
        }

        private void ControlTabs_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            var (_, canInsert, _, _) = CheckPermissions();
            SetTabVisibility("Додати категорію", canInsert);
            SetTabVisibility("Додати постачальника", canInsert);
            SetTabVisibility("Додати працівника", canInsert);
            if (ControlTabs.SelectedItem is TabItem selectedTab)
            {
                if (selectedTab.Header.ToString() == "Створити закупівлю")
                {
                    LoadDataForSupplierOrderTab();
                }
            }
        }

        private void SetTabVisibility(string header, bool isVisible)
        {
            foreach (TabItem tab in ControlTabs.Items)
            {
                if (tab.Header?.ToString() == header)
                {
                    tab.Visibility = isVisible ? Visibility.Visible : Visibility.Collapsed;
                    break;
                }
            }
        }

        private bool ValidateConnection()
        {
            if (connection.State != ConnectionState.Open)
            {
                MessageBox.Show("Втрачено з'єднання з базою даних");
                LogOut_Click(null, null);
                return false;
            }
            return true;
        }

        private object NullIfEmpty(string value)
        {
            return string.IsNullOrWhiteSpace(value)
                ? DBNull.Value
                : (object)value;
        }

        private void DataDisplayGrid_AutoGeneratingColumn(object? sender, DataGridAutoGeneratingColumnEventArgs e)
        {
            if (e.PropertyType == typeof(DateTime) || e.PropertyType == typeof(DateTime?))
            {
                if (e.Column is DataGridTextColumn col)
                {
                    col.Binding = new Binding(e.PropertyName) { StringFormat = "d" }; // тільки дата
                }
            }
        }

        // --- Класи моделей ---
        public class ProductInfo
        {
            public string ProductID { get; set; } = string.Empty;
            public string ProductName { get; set; } = string.Empty;
            public decimal Price { get; set; }
        }

        public class SaleDetailGridItem : INotifyPropertyChanged
        {
            private string _productID = string.Empty;
            public string ProductID
            {
                get => _productID;
                set
                {
                    if (_productID != value)
                    {
                        _productID = value;
                        OnPropertyChanged(nameof(ProductID));
                        UpdatePriceAndNameBasedOnProductSelection();
                    }
                }
            }
            private string _productName = string.Empty;
            public string ProductName
            {
                get => _productName;
                set
                {
                    if (_productName != value)
                    {
                        _productName = value;
                        OnPropertyChanged(nameof(ProductName));
                    }
                }
            }
            private int _quantity;
            public int Quantity
            {
                get => _quantity;
                set
                {
                    if (_quantity != value)
                    {
                        _quantity = value;
                        OnPropertyChanged(nameof(Quantity));
                    }
                }
            }
            private decimal _unitPrice;
            public decimal UnitPrice
            {
                get => _unitPrice;
                set
                {
                    if (_unitPrice != value)
                    {
                        _unitPrice = value;
                        OnPropertyChanged(nameof(UnitPrice));
                    }
                }
            }
            private static List<SaleDetailGridItem>? _availableProductsList;
            public static void SetAvailableProducts(List<SaleDetailGridItem> products)
            {
                _availableProductsList = products;
            }
            private void UpdatePriceAndNameBasedOnProductSelection()
            {
                if (_availableProductsList != null && !string.IsNullOrEmpty(ProductID))
                {
                    var productInfo = _availableProductsList.FirstOrDefault(p => p.ProductID == this.ProductID);
                    if (productInfo != null)
                    {
                        this.UnitPrice = productInfo.UnitPrice;
                        this.ProductName = productInfo.ProductName;
                    }
                }
            }
            public event PropertyChangedEventHandler? PropertyChanged;
            protected virtual void OnPropertyChanged(string propertyName)
            {
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
            }
        }

        public class SupplierOrderDetailItem : INotifyPropertyChanged
        {
            private string _productID = string.Empty;
            public string ProductID
            {
                get => _productID;
                set
                {
                    if (_productID != value)
                    {
                        _productID = value;
                        OnPropertyChanged(nameof(ProductID));
                        UpdatePriceAndNotify();
                    }
                }
            }
            private int _quantity = 1;
            public int Quantity
            {
                get => _quantity;
                set
                {
                    if (_quantity != value && value > 0)
                    {
                        _quantity = value;
                        OnPropertyChanged(nameof(Quantity));
                        OnPropertyChanged(nameof(TotalAmount));
                    }
                }
            }
            private decimal _unitPrice;
            public decimal UnitPrice
            {
                get => _unitPrice;
                set
                {
                    if (_unitPrice != value)
                    {
                        _unitPrice = value;
                        OnPropertyChanged(nameof(UnitPrice));
                        OnPropertyChanged(nameof(TotalAmount));
                    }
                }
            }
            public decimal TotalAmount => Quantity * UnitPrice;
            private void UpdatePriceAndNotify()
            {
                var product = MainWindow.AvailableProductsForOrder.FirstOrDefault(p => p.ProductID == _productID);
                if (product != null)
                {
                    UnitPrice = product.Price;
                }
                else
                {
                    UnitPrice = 0;
                }
            }
            public event PropertyChangedEventHandler? PropertyChanged;
            protected virtual void OnPropertyChanged(string propertyName)
            {
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
            }
        }

        // --- INotifyPropertyChanged реалізація ---
        public event PropertyChangedEventHandler? PropertyChanged;
        protected virtual void OnPropertyChanged(string propertyName)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}