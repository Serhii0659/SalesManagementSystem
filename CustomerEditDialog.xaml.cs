using System.Windows;

namespace SalesManagementSystem
{
    public partial class CustomerEditDialog : Window
    {
        public string CustomerName => NameBox.Text.Trim();
        public string CustomerPhone => PhoneBox.Text.Trim();
        public string CustomerEmail => EmailBox.Text.Trim();

        public CustomerEditDialog(string name, string phone, string email)
        {
            InitializeComponent();
            NameBox.Text = name;
            PhoneBox.Text = phone;
            EmailBox.Text = email;
            NameBox.Focus();
        }

        private void Ok_Click(object sender, RoutedEventArgs e)
        {
            if (string.IsNullOrWhiteSpace(NameBox.Text))
            {
                MessageBox.Show("ПІБ не може бути порожнім.", "Помилка", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            DialogResult = true;
        }
    }
}