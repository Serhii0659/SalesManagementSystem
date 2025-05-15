using System.Windows;

namespace SalesManagementSystem
{
    public partial class ProductEditDialog : Window
    {
        public string ProductName => NameBox.Text.Trim();
        public decimal ProductPrice
        {
            get
            {
                decimal.TryParse(PriceBox.Text.Trim(), out var val);
                return val;
            }
        }

        public ProductEditDialog(string name, decimal price)
        {
            InitializeComponent();
            NameBox.Text = name;
            PriceBox.Text = price.ToString("0.##");
            NameBox.Focus();
        }

        private void Ok_Click(object sender, RoutedEventArgs e)
        {
            if (string.IsNullOrWhiteSpace(NameBox.Text) || !decimal.TryParse(PriceBox.Text, out var price) || price <= 0)
            {
                MessageBox.Show("Введіть коректні дані для назви та ціни!", "Помилка", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            DialogResult = true;
        }
    }
}
